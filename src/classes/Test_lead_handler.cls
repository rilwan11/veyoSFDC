@istest
public class Test_lead_handler {
	static testMethod void convertLeadToContact(){
		// Test setup data
        
        Account oldAccount = new Account(name = 'My Company');
        insert oldAccount;
        
        Contact oldContact = new Contact(lastName = 'Doe', 
                                         email = 'johndoe@company.com', 
                                         accountID = oldAccount.id);
        insert oldContact;
        
        Lead myLead = new Lead(FirstName = 'John',
                            LastName = 'Doe',
                            Company = 'My Company',
                            Status = 'Open',
                            Email = 'johndoe@company.com');
        insert myLead;
        
        List<Lead> leads = new List<Lead>();
        for(Integer i = 0; i > 10; i++) {
            Lead l = new Lead();
            l.FirstName = 'John';
            l.LastName = 'Doe';
            l.Company = 'Your Company';
            l.Status = 'Open';
            l.Email = 'lead@company.com';
            leads.add(l);
        } 
        insert leads;
        
        //End test setup
        Test.startTest();
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name = 'My Company'];
        //system.assert(accounts.size() == 1);
        
        List<Account> account = [SELECT Id, Name FROM Account WHERE Name = 'Your Company'];
        system.debug(account.size());
        //system.assert(account.size() == 1);
        
        List<Contact> contacts = [SELECT Id, Email FROM Contact WHERE Email = 'johndoe@company.com'];
        //system.assert(contacts.size() == 1);
        
        List<Contact> mycontacts = [SELECT Id, Email FROM Contact WHERE Email = 'lead@company.com'];
        system.debug(mycontacts.size());
        //system.assert(mycontacts.size() == 1);
        Test.stopTest();
	}
}