public class lead_handler {
    public static void convertLeads(List<Lead> triggerNew){
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        List<Database.LeadConvertResult> conversionResults = new List<Database.LeadConvertResult>();
        Set<String> distinctCompanyNames = new Set<String>();
        Set<String> distinctEmailAddresses = new Set<String>();
        List<Account> accountsToUpdate = new List<Account>();
        List<Account> preExistingAccountsForLeads = new List<Account>();
        Set<Id> preExistingAccountIDsForLead = new Set<Id>();
        Map<String, Account> mapPreExistingAccountNamesToAccounts = new Map<String, Account>();
        List<Contact> preExistingContactsForLeads = new List<Contact>();
        Map<String, Contact> mapPreExistingContactEmailsToContacts = new Map<String, Contact>();
        Map<Id, Lead> leadsWhoWereCreatingAccountsFrom = new Map<Id, Lead>();
        Map<Id, Id> mapNewlyCreatedAccountIdToLeadId = new Map<Id, Id>();
        Map<Id, Account> mapNewlyCreatedAccounts = new Map<Id, Account>();
        
        //get the convertstatus
        LeadStatus convertStatus = [SELECT MasterLabel
                                      FROM LeadStatus
                                      WHERE IsConverted = true
                                      LIMIT 1];
        
        // get a collection of distinct Company Names & Email addresses to avoid creating dupes...
        for (Lead l : triggerNew) {
            if (l.Email != null && l.Email != '' && !l.isConverted) {
                distinctCompanyNames.add(l.Company);
                distinctEmailAddresses.add(l.Email);
            }
        }
        
        // get all Accounts where the Name is in the Company names on these Leads
        if (distinctCompanyNames != null && !distinctCompanyNames.isEmpty()) {
            preExistingAccountsForLeads =  [SELECT Id, Name
                                            FROM Account 
                                            WHERE Name IN :distinctCompanyNames
                                            ORDER BY CreatedDate];

            if(preExistingAccountsForLeads != null && preExistingAccountsForLeads.size() > 0) {
                for(Account a : preExistingAccountsForLeads) {
                    preExistingAccountIDsForLead.add(a.Id);
                }
            }
        }
        
        // create a map from String --> Account for the company name to AccountId
        if (preExistingAccountsForLeads != null && !preExistingAccountsForLeads.isEmpty()) {
            for (Account a : preExistingAccountsForLeads) {
                if(a == null) continue;
                mapPreExistingAccountNamesToAccounts.put(a.Name.toLowerCase(), a);
            }
        }

        // get all Contacts where the Email is in the Email addresses on these Leads [for the Accounts that were found]
        if (distinctEmailAddresses != null && !distinctEmailAddresses.isEmpty()) {
            preExistingContactsForLeads = [SELECT Id, Name, Email, AccountId FROM Contact WHERE Email IN :distinctEmailAddresses];
        }
        // create a map from String --> Contact for the email address to ContactId
        if (preExistingContactsForLeads != null && !preExistingContactsForLeads.isEmpty()) {
            for (Contact c : preExistingContactsForLeads) {
                mapPreExistingContactEmailsToContacts.put(c.Email.toLowerCase(), c);
            }
        }
        
        for (Lead l : triggerNew) {
            if (!l.isConverted && l.Email != null && l.Email != '') {
                // set up a LeadConvert - Status = 'Lead'
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(l.Id);
                lc.setConvertedStatus(convertStatus.MasterLabel);
                lc.setDoNotCreateOpportunity(true);
                
                // get the Accounts that already exist 
			 	if (mapPreExistingAccountNamesToAccounts.get(l.Company.toLowerCase()) != null) {
                    // if the lead's Company already exists as an Account, get the account's id and setAccountId(a.Id);
                    Account a = mapPreExistingAccountNamesToAccounts.get(l.Company.toLowerCase());
                    lc.setAccountId(a.Id);
					
                    // if the lead's Email already exists as a Contact for the same Account, get the contact's id and setContactId(c.Id);
                    if (mapPreExistingContactEmailsToContacts.get(l.Email.toLowerCase()) != null) {
                        Contact c = mapPreExistingContactEmailsToContacts.get(l.Email.toLowerCase());
                        if (c.AccountId == a.Id) {
                            lc.setContactId(c.Id);
                        }
                    }
                } else { // if the lead's Company does NOT already exist as an Account either by Name or Domain, capture the leadId in a collection so we can go get the AccountIds after they're created and update some values on them later
                    leadsWhoWereCreatingAccountsFrom.put(l.Id, l);
                }
            
                // don't allow more than one Contact to have the same Email address in the system... in order to avoid DUPE CONTACTS...
                if(mapPreExistingContactEmailsToContacts.get(l.Email.toLowerCase()) != null) {
                    Contact c = mapPreExistingContactEmailsToContacts.get(l.Email.toLowerCase());
                    lc.setContactId(c.Id);
                    lc.setAccountId(c.AccountId);
                }                 
                leadConverts.add(lc);
            }
        }
                
        if (!leadConverts.isEmpty()) {
            system.debug('lead_handler.convertLeads() :: leadConverts.size(): '+leadConverts.size());
            system.debug('lead_handler.convertLeads() :: leadConverts: '+leadConverts);
            system.debug('lead_handler.convertLeads() :: leadsWhoWereCreatingAccountsFrom.size(): '+leadsWhoWereCreatingAccountsFrom.size());
            system.debug('lead_handler.convertLeads() :: leadsWhoWereCreatingAccountsFrom: '+leadsWhoWereCreatingAccountsFrom);

            // conversion 3..2..1..
            conversionResults = Database.convertLead(leadConverts);

            for (Database.LeadConvertResult result : conversionResults) {
                if (result.isSuccess() && result.getAccountId() != null) {
                    mapNewlyCreatedAccountIdToLeadId.put(result.getAccountId(), result.getLeadId());
                }
            }

            if (!mapNewlyCreatedAccountIdToLeadId.isEmpty()) {
                mapNewlyCreatedAccounts = new Map<Id, Account>([SELECT Id, Name
                                                            FROM Account 
                                                            WHERE Id IN :mapNewlyCreatedAccountIdToLeadId.keySet()]);


                if (!mapNewlyCreatedAccounts.isEmpty()) {
                    // Account updates...
                    for (Account a : mapNewlyCreatedAccounts.values()) {
                        Lead l = leadsWhoWereCreatingAccountsFrom.get(mapNewlyCreatedAccountIdToLeadId.get(a.Id));
                        if(l == null) continue; //For New Leads who are matched to a correct account by company name but are not duplicate in the system

                        // update the existing Account...
                        if(l.Email != null) {
                            accountsToUpdate.add(a);
                        }
                    }

                    // update existing Accounts...
                    if (!accountsToUpdate.isEmpty()) {
                        update accountsToUpdate;
                    }                    
                }
            
            }
        }
    }
}