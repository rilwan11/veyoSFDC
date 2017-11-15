/**
 * Created by krizia on 10/19/17.
 * All logic for CaseTrigger to handle Case Aging Histories or anything dealing with time on the Case (Grievance Note) object
 */

public with sharing class CaseTriggerHandler {
    //Manage Trigger to prevent second firing when Case is updated within this class
    public static boolean firstRun = true;


    /**
     * Krizia: all new Cases (Grievance Notes) must have all fields set to initial values for later additions and
     *      Created date needs to be initialized to now for good record keeping.
     * @param newCases - all newly inserted Cases (Grievance Notes) that triggered this call
     */
    public static void insertCaseTime(List<Case> newCases) { //Runs as Before Insert
        //Update all new Cases to start at 0 right now for custom fields
        System.debug('CaseTriggerHandler::: insertCaseTime:: before insert');

        //Iterate over new Cases giving default values for their Totalling Fields
        for (Case upC : newCases) {
            upC.Case_Age_In_Business_Hours__c = 0.0;
            upC.Time_With_Support__c = 0.0;
            upC.Time_With_Customer__c = 0.0;
            upC.Follow_Up_Age__c = 0.0;
            upC.Follow_Up_Time_with_Support__c = 0.0;
            upC.Follow_Up_Time_with_Customer__c = 0.0;
            upC.Created__c = System.now();
            upC.User_Account__c = upC.AccountId;
        }
    } //public static void insertCaseTime(List<Case> newCases)

    /**
     * Krizia: compare Trigger.new to Trigger.old in order to see if the Status has changed,
     *      close old CAH and insert new one if the Status has changed, otherwise do nothing
     * @param newCases Trigger.new
     * @param oldCases Trigger.oldMap
     */
    public static void insertCaseAgingHistory(List<Case> newCases, Map<Id, Case> oldCases) { //Runs as After Insert / After Update
        System.debug('CaseTriggerHandler::: insertCaseAgingHistory:: after insert / after update');
        //Insert Case Aging History records
        List<Case_Aging_History__c> cahList = new List<Case_Aging_History__c>();


        for (Case c : newCases) {
            //Old case to compare if the Status changed
            if (oldCases != null) {
                System.debug(string.valueOf(oldCases.get(c.Id).Status) + '  --  ' + string.valueOf(c.Status));
                String s = oldCases.get(c.Id).Status;
                if (s != c.Status) {
                    //Add to insert list
                    cahList.add(makeNewCaseAgingHistory(c));
                }
            }
            else { //Entirely new case
                cahList.add(makeNewCaseAgingHistory(c));
            }
        }

        if (!cahList.isEmpty()) {
            System.debug('CaseTriggerHandler::: insertCaseAgingHistory:: inserting new Case Aging History record(s)');
            insert cahList;
        }
    } //public static void insertCaseAgingHistory(List<Case> newCases)

    /**
     * Krizia: build new Case Aging History for Cases (Grievance Notes) that need a new CAH
     *      -Assign checkbox of Follow Up Period after Case enters into Follow Up Requested
     * @param c Case needing a new CAH
     *
     * @return
     */
    private static Case_Aging_History__c makeNewCaseAgingHistory(Case c) {
        //Create new Case Aging History for each Case to begin tracking Status changes
        Case_Aging_History__c cah = new Case_Aging_History__c(
                Case__c = c.Id,
                Historical_Status__c = c.Status,
                Start_Time__c = System.now(),
                Case_Aging_Line_Item_Total__c = 0.0
        );

        //Track Follow Up status changes separately
        if (c.Follow_Up_Period__c == true) {
            cah.Follow_Up_Period__c = true;
        }

        return cah;
    } //private static Case_Aging_History__c makeNewCaseAgingHistory(Case c)

    /**
     * Krizia: Separate inserted Cases from Updated Cases in order to make sure inserted Cases are initialized to zeros
     *      -Logic to determine when to add time to Time with Customer, Time with Support, Follow Up Time with Customer,
     *      Follow Up Time with Support, Case Age in Business Hours, and/or Follow Up Age and whether in a Follow Up Period
     * @param cases Trigger.new
     * @param oldCases Trigger.oldMap
     */
    public static void updateCaseTime(List<Case> cases, Map<Id, Case> oldCases) {
        //Convert to Set
        Set<Case> CaseSet = new Set<Case>(cases);
        //Cases that will be sent to insertCaseTime()
        List<Case> insertCases = new List<Case>();
        //Cases that changed Status and need a new Case Aging History
        List<Case> needNewCAHCases = new List<Case>();


        //Update existing Cases to reflect time spent with Customer vs Support
        Set<String> supportStopStatusSet = new Set<String>();
        supportStopStatusSet.add('Pending Information'); //Waiting on Customer
        supportStopStatusSet.add('Resolved'); //Closed
        supportStopStatusSet.add('Follow Up Completed'); //Final closing
        Set<String> supportOpenStatusSet = new Set<String>();
        supportOpenStatusSet.add('Submitted');
        supportOpenStatusSet.add('In Progress');
        supportOpenStatusSet.add('In Progress - Pending Info from Transportation Provider');
        supportOpenStatusSet.add('Follow Up Requested');

        //Get the default business hours
        BusinessHours defaultHours = [SELECT Id FROM BusinessHours WHERE isDefault = true];

        //Retrieve all Case Aging Histories in connection to incoming Cases that are not yet closed (should be one per Case)
        List<Case_Aging_History__c> incomingCAH = new List<Case_Aging_History__c>();
        incomingCAH = [SELECT Id, Historical_Status__c, Case__c, Start_Time__c, End_Time__c, Case_Aging_Line_Item_Total__c, Follow_Up_Period__c
                           FROM Case_Aging_History__c
                           WHERE Case__c IN :CaseSet AND End_Time__c = null];
        System.debug('CaseTriggerHandler::: updateCaseTime:: incoming Case Aging Histories' + string.valueOf(incomingCAH));

        //Case Aging History List has at least one record
        if (!incomingCAH.isEmpty()) {
           //Map all Case Aging Histories to their incoming Case
           Map<Id, List<Case_Aging_History__c>> mapCaseToCaseAgingHistories = new Map<Id, List<Case_Aging_History__c>>();

           //Create map placement for each Case
           for (Case c : CaseSet) {
               mapCaseToCaseAgingHistories.put(c.Id, new List<Case_Aging_History__c>());
               System.debug('CaseTriggerHandler::: updateCaseTime:: mapping Case ' + string.valueOf(c.Id));
           }

           //Add Case Aging Histories to those Cases that have one
           for (Case_Aging_History__c cah : incomingCAH) {
               mapCaseToCaseAgingHistories.get(cah.Case__c).add(cah);
               System.debug('CaseTriggerHandler::: updateCaseTime:: mapping Case Aging History ' + string.valueOf(cah.Id));
           }

           //Update Case Aging Histories for DML operation
           List<Case_Aging_History__c> updateCAHList = new List<Case_Aging_History__c>();

           //Use each Case's IAHs to calculate Totals and to create a new one if there is a Status update
           for (Id CaseId : mapCaseToCaseAgingHistories.keySet()) {
               //Case to work with on this iteration
               Case c = (Case)System.Trigger.newMap.get(CaseId);
               Case oldCase = (Case)System.Trigger.oldMap.get(CaseId);
               System.debug('Case ' + string.valueOf(c));

               //Jump into Follow Up Period and skip adding time between 'Resolved' and 'Follow Up Requested' to Case Age
               if (c.Status == 'Follow Up Requested') {
                   c.Follow_Up_Period__c = true;
               }

               //Enter to close out open Case Aging History if the Status changed
               if (!mapCaseToCaseAgingHistories.get(CaseId).isEmpty()) {
                   List<Case_Aging_History__c> cahList = mapCaseToCaseAgingHistories.get(CaseId);
                   System.debug('Made it into IF - cahList: ' + string.valueOf(cahList));

                   //Go through all Case Aging History for current Case
                   for (Case_Aging_History__c cah : cahList) {
                       //Check if clock should be stopped if End Time doesn't exist
                       if (cah.End_Time__c == null) {
                           //Close Case Aging History on Status change and create new one
                           System.debug('old status: ' + string.valueOf(oldCases.get(CaseId).Status) + ' - new status: ' + string.valueOf(c.Status));
                           if (oldCase.Status != c.Status) {
                               System.debug('Status conflict');
                               if (cah.Historical_Status__c == 'Resolved') {
                                   cah.End_Time__c = cah.Start_Time__c;
                               }
                               else {
                                   cah.End_Time__c = System.now();
                               }
                               cah.Case_Aging_Line_Item_Total__c = BusinessHours.diff(defaultHours.Id, cah.Start_Time__c, cah.End_Time__c) / 3600000.0; //3600000 is an hour
                               System.debug('Case_Aging_Line_Item_Total__c: ' + string.valueOf(cah.Case_Aging_Line_Item_Total__c));

                               //If completed a customer time, add to Customer total
                               if (supportStopStatusSet.contains(oldCases.get(CaseId).Status)) {
                                   System.debug('CaseTriggerHandler::: updateCaseTime:: support stop');
                                   //Separate Follow Up and non Follow Up
                                   if (c.Follow_Up_Period__c == true) {
                                       c.Follow_Up_Time_with_Customer__c += cah.Case_Aging_Line_Item_Total__c;
                                   } else {
                                       c.Time_with_Customer__c += cah.Case_Aging_Line_Item_Total__c;
                                   }
                               } //If completed a support time, add to Support total
                               else {
                                   System.debug('CaseTriggerHandler::: updateCaseTime:: customer stop');
                                   //Separate Follow Up and non Follow Up
                                   if (c.Follow_Up_Period__c == true) {
                                       c.Follow_Up_Time_with_Support__c = c.Follow_Up_Time_with_Support__c + cah.Case_Aging_Line_Item_Total__c;
                                   } else {
                                       c.Time_with_Support__c = c.Time_with_Support__c + cah.Case_Aging_Line_Item_Total__c;
                                   }
                               }
                               //Add together both types of Case hours
                               c.Case_Age_In_Business_Hours__c = c.Time_with_Customer__c + c.Time_with_Support__c;
                               c.Follow_Up_Age__c = c.Follow_Up_Time_with_Support__c + c.Follow_Up_Time_with_Customer__c;
                               System.debug('CaseTriggerHandler::: updateCaseTime:: closing out Case Aging History ' + string.valueOf(cah));
                               updateCAHList.add(cah);
                           }
                       }
                   }
               } else { //Cases that do not have any Case Aging Histories, so they need to be inserted
                   insertCases.add(c);
               }
           }

           //If there are new Cases mixed with updates, insert them
           if (!insertCases.isEmpty()) {
               insert insertCases; //should trigger insertCaseTime
               System.debug('CaseTriggerHandler::: updateCaseTime:: should go to insertCases then insertCaseAgingHistory');
           }
           //Update those that had times ended
           if (!updateCAHList.isEmpty()) {
               System.debug('CaseTriggerHandler::: updateCaseTime:: update updateCAHList');
               update updateCAHList;
           }
           //Update old Case Aging Histories
           update incomingCAH;
        } //if (!incomingIAH.isEmpty())
    } //public static void updateCaseTime(List<Case> Cases)


    /**
     * Krizia: automatically set Due Dates based on the Account level decision on days per Priority
     *
     * @param Cases input cases from Before Insert
     */
    public static void setDueDate(List<Case> Cases, Map<Id, Case> caseMap) {
        System.debug('CaseTriggerHandler::: setDueDate');
        //Get all Accounts
        Map<Id, Account> accountMap = getAccountMap(Cases);

        //Get the default business hours for setting Due Dates on Business Days
        BusinessHours defaultHours = [SELECT Id FROM BusinessHours WHERE isDefault = true];

        for (Case c : Cases) {
            Account a = accountMap.get(c.AccountId);
            System.debug('CaseTriggerHandler::: setDueDate::: a: ' + string.valueOf(a));
            Integer days = 0;
            //Expedited Due Date
            if (c.Priority == 'Expedited') {
                days = (Integer)a.Expedited_Priority_Days__c * (8 * 3600000); //set days * 8 hours in milliseconds
            }
            else { //General Due Date
                days = (Integer)a.General_Priority_Days__c * (8 * 3600000); //set days * 8 hours in milliseconds
            }

            //Set the due date according to the number of days specified by Priority
            c.Due_Date__c = BusinessHours.add(defaultHours.Id, System.now(), days);
        }
    } //public static void setDueDate(List<Case> Cases)


    /** Krizia: determine which Email Templates have been identified as sending out automatically on the Account
     *
     */
    public static void sendAutomaticEmails(List<Case> newCases, Map<Id, Case> oldCasesMap) {
        System.debug('CaseTriggerHandler::: sendAutomaticEmails:: newCases: ' + string.valueOf(newCases));
        //Map Accounts in order to access their Grievance Email Configurations
        Map<Id, Account> accountMap = getAccountMap(newCases);


        for (Case c : newCases) {
            System.debug('FOR LOOP' + string.valueOf(c.CaseNumber) + string.valueOF(c.Status));
            //Check first to see if the Status is one of the available Automatic Mailing ones and it hasn't already fired
            if (c.Status == 'Resolved' && oldCasesMap.get(c.Id).Status != 'Resolved') {
                System.debug('CaseTriggerHandler::: sendAutomaticEmails:: in Resolved');
                Account a = (Account) accountMap.get(c.AccountId);
                sendEmail(c, a);
            }
            else if (c.Status == 'Follow Up Requested' && oldCasesMap.get(c.Id).Status != 'Follow Up Requested') {
                System.debug('CaseTriggerHandler::: sendAutomaticEmails:: in Follow Up Requested');
                Account a = (Account) accountMap.get(c.AccountId);
                sendEmail(c, a);
            }
            else if (c.Status == 'Follow Up Completed' && oldCasesMap.get(c.Id).Status != 'Follow Up Completed') {
                System.debug('CaseTriggerHandler::: sendAutomaticEmails:: in Follow Up Completed');
                Account a = (Account) accountMap.get(c.AccountId);
                sendEmail(c, a);
            }
        }

    } // public static void sendAutomaticEmails(List<Case> Cases)


    /**
     * Krizia: determine which Email Templates have been identified as sending out automatically on the Account upon insert as Submitted
     *
     * @param newCases
     */
    public static void sendAutomaticEmailsOnInsert(List<Case> newCases) {
        System.debug('CaseTriggerHandler::: sendAutomaticEmailsOnInsert:: ');
        //Map Accounts in order to access their Grievance Email Configurations
        Map<Id, Account> accountMap = getAccountMap(newCases);


        for (Case c : newCases) {
            //Check first to see if the Status is one of the available Automatic Mailing ones and it hasn't already fired
            if (c.Status == 'Submitted') {
                System.debug('CaseTriggerHandler::: sendAutomaticEmailsOnInsert:: in Submitted');
                Account a = (Account) accountMap.get(c.AccountId);
                sendEmail(c, a);
            }
        }
    } //public static void sendAutomaticEmailsOnInsert(List<Case> newCases)

    /**
     * Krizia: Get all Accounts associated with the Cases
     *
     * @param Cases
     *
     * @return
     */
    public static Map<Id, Account> getAccountMap(List<Case> Cases) {
        //Gather all Account Ids
        Set<Id> accountIds = new Set<Id>();
        for (Case c : Cases) {
            //only add Accounts that are not already in the list
            if (!accountIds.contains(c.AccountId)) {
                accountIds.add(c.AccountId);
            }
        }

        //All Accounts connected to these Cases
        List<Account> aList = [SELECT Id, General_Priority_Days__c, Expedited_Priority_Days__c,
            Default_Account_Email_Address__c, Email_Template_1__c, Email_Recipients_1__c, Automatic_Event_1__c,
                Email_Template_2__c, Email_Recipients_2__c, Automatic_Event_2__c,
                Email_Template_3__c, Email_Recipients_3__c, Automatic_Event_3__c,
                Email_Template_4__c, Email_Recipients_4__c, Automatic_Event_4__c,
                Email_Template_5__c, Email_Recipients_5__c, Automatic_Event_5__c
                                FROM Account
                                WHERE Id IN: accountIds];
        System.debug(aList);

        //Convert Accounts to map in order to access in the Case for loop
        Map<Id, Account> accountMap = new Map<Id, Account>();
        for (Account a : aList) {
            if (!accountMap.containsKey(a.Id)) {
                accountMap.put(a.Id, a);
            }
        }

        System.debug('CaseTriggerHandler::: getAccountMap:: ' + string.valueOf(accountMap));
        return accountMap;
    } //public static Map<Id, Account> getAccountMap(List<Case> Cases)


    /**
     * Krizia: commonalities from sendAutomaticEmails to figure out the recipients
     *
     * @param c
     * @param a
     */
    public static void sendEmail(Case c, Account a) {
        Contact defaultEmail = [SELECT Id, FirstName, LastName, Email
                                    FROM Contact
                                    WHERE Email = :a.Default_Account_Email_Address__c
                                    LIMIT 1];
        List<Contact> staticGroup = [SELECT Id, FirstName, LastName, Email, AccountId
                                        FROM Contact
                                        WHERE AccountId =: a.Id AND Member_of_Static_Account_Email_Group__c = true];
        System.debug('CaseTriggerHandler::: sendEmail:: default account email address: ' + string.valueOf(a.Default_Account_Email_Address__c));


        //Check to see if an Automatic Event matches this Status
        if (a.Automatic_Event_1__c != null) {
            //Recipients
            String[] toRecipients = new List<String>();
            Id targetId;
            if (a.Automatic_Event_1__c.contains(c.Status)) {
                System.debug('1: ' + string.valueOf(a.Automatic_Event_1__c));
                //Go through recipients
                if (a.Email_Recipients_1__c.contains('Submitting Contact') && c.ContactEmail != null) {
                    toRecipients.add(c.ContactEmail);
                    targetId = c.ContactId;
                }
                if (a.Email_Recipients_1__c.contains('Default Account Email Address') && defaultEmail.Email != null) {
                    toRecipients.add(defaultEmail.Email);
                    if (targetId == null) { targetId = defaultEmail.Id; }
                }
                if (a.Email_Recipients_1__c.contains('Static Account Email Group') && staticGroup.size() > 0) {
                    if (targetId == null) { targetId = staticGroup[0].Id; }
                    for (Contact contact : staticGroup) {
                        toRecipients.add(contact.Email);
                    }
                }
                System.debug('CaseTriggerHandler::: sendEmail:: 1 ' + string.valueOf(toRecipients));
                Boolean result = CaseEmail.sendEmailFromModal(c, toRecipients, targetId, a.Email_Template_1__c);
                System.debug('automatic 1: ' + string.valueOf(result));
            }
        }
        if (a.Automatic_Event_2__c != null) {
            //Recipients
            String[] toRecipients = new List<String>();
            Id targetId;
            if (a.Automatic_Event_2__c.contains(c.Status)) {
                System.debug('2: ' + string.valueOf(a.Automatic_Event_2__c));
                //Go through recipients
                if (a.Email_Recipients_2__c.contains('Submitting Contact') && c.ContactEmail != null) {
                    toRecipients.add(c.ContactEmail);
                    targetId = c.ContactId;
                }
                if (a.Email_Recipients_2__c.contains('Default Account Email Address') && defaultEmail.Email != null) {
                    toRecipients.add(defaultEmail.Email);
                    if (targetId == null) { targetId = defaultEmail.Id; }
                }
                if (a.Email_Recipients_2__c.contains('Static Account Email Group') && staticGroup.size() > 0) {
                    if (targetId == null) { targetId = staticGroup[0].Id; }
                    for (Contact contact : staticGroup) {
                        toRecipients.add(contact.Email);
                    }
                }
                System.debug('CaseTriggerHandler::: sendEmail:: 2 ' + string.valueOf(toRecipients));
                Boolean result = CaseEmail.sendEmailFromModal(c, toRecipients, targetId, a.Email_Template_2__c);
                System.debug('automatic 2: ' + string.valueOf(result));
            }
        }
        if (a.Automatic_Event_3__c != null) {
            //Recipients
            String[] toRecipients = new List<String>();
            Id targetId;
            if (a.Automatic_Event_3__c.contains(c.Status)) {
                System.debug('3: ' + string.valueOf(a.Automatic_Event_3__c));
                //Go through recipients
                if (a.Email_Recipients_3__c.contains('Submitting Contact') && c.ContactEmail != null) {
                    toRecipients.add(c.ContactEmail);
                    targetId = c.ContactId;
                }
                if (a.Email_Recipients_3__c.contains('Default Account Email Address') && defaultEmail.Email != null) {
                    toRecipients.add(defaultEmail.Email);
                    if (targetId == null) { targetId = defaultEmail.Id; }
                }
                if (a.Email_Recipients_3__c.contains('Static Account Email Group') && staticGroup.size() > 0) {
                    if (targetId == null) { targetId = staticGroup[0].Id; }
                    for (Contact contact : staticGroup) {
                        toRecipients.add(contact.Email);
                    }
                }
                System.debug('CaseTriggerHandler::: sendEmail:: 3 ' + string.valueOf(toRecipients));
                Boolean result = CaseEmail.sendEmailFromModal(c, toRecipients, targetId, a.Email_Template_3__c);
                System.debug('automatic 3: ' + string.valueOf(result));
            }
        }
        if (a.Automatic_Event_4__c != null) {
            //Recipients
            String[] toRecipients = new List<String>();
            Id targetId;
            if (a.Automatic_Event_4__c.contains(c.Status)) {
                System.debug('4: ' + string.valueOf(a.Automatic_Event_4__c));
                //Go through recipients
                if (a.Email_Recipients_4__c.contains('Submitting Contact') && c.ContactEmail != null) {
                    toRecipients.add(c.ContactEmail);
                    targetId = c.ContactId;
                }
                if (a.Email_Recipients_4__c.contains('Default Account Email Address') && defaultEmail.Email != null) {
                    toRecipients.add(defaultEmail.Email);
                    if (targetId == null) { targetId = defaultEmail.Id; }
                }
                if (a.Email_Recipients_4__c.contains('Static Account Email Group') && staticGroup.size() > 0) {
                    if (targetId == null) { targetId = staticGroup[0].Id; }
                    for (Contact contact : staticGroup) {
                        toRecipients.add(contact.Email);
                    }
                }
                System.debug('CaseTriggerHandler::: sendEmail:: 4 ' + string.valueOf(toRecipients));
                Boolean result = CaseEmail.sendEmailFromModal(c, toRecipients, targetId, a.Email_Template_4__c);
                System.debug('automatic 4: ' + string.valueOf(result));
            }
        }
        if (a.Automatic_Event_5__c != null) {
            //Recipients
            String[] toRecipients = new List<String>();
            Id targetId;
            if (a.Automatic_Event_5__c.contains(c.Status)) {
                System.debug('5: ' + string.valueOf(a.Automatic_Event_5__c));
                //Go through recipients
                if (a.Email_Recipients_5__c.contains('Submitting Contact') && c.ContactEmail != null) {
                    toRecipients.add(c.ContactEmail);
                    targetId = c.ContactId;
                }
                if (a.Email_Recipients_5__c.contains('Default Account Email Address') && defaultEmail.Email != null) {
                    toRecipients.add(defaultEmail.Email);
                    if (targetId == null) { targetId = defaultEmail.Id; }
                }
                if (a.Email_Recipients_5__c.contains('Static Account Email Group') && staticGroup.size() > 0) {
                    if (targetId == null) { targetId = staticGroup[0].Id; }
                    for (Contact contact : staticGroup) {
                        toRecipients.add(contact.Email);
                    }
                }
                System.debug('CaseTriggerHandler::: sendEmail:: 5 ' + string.valueOf(toRecipients));
                Boolean result = CaseEmail.sendEmailFromModal(c, toRecipients, targetId, a.Email_Template_5__c);
                System.debug('automatic 5: ' + string.valueOf(result));
            }
        }
    } //public void sendEmail(Case c, Account a)

} //public class CaseTriggerHandler