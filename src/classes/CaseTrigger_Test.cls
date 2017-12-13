/**
 * Created by krizia on 10/20/17.
 */
@isTest
public with sharing class CaseTrigger_Test {

    /**
    * Krizia: code coverage first, then tweak to get proper values
     * AccountTrigger: 100%
        AccountTriggerHandler: 91%
        CaseEmail: 88%
        CaseTrigger: 100%
        CaseTriggerHandler: 80%
     */


    public static testmethod void insertCase() {

        Id aRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId();
        Contact testContact = new Contact(
                LastName = 'Test1',
                Email = 'mr@test.com'
        );
        insert testContact;
        Account a = new Account(
                Name = 'Test Account',
                RecordTypeId = aRecordType,
                Call_Center_Can_Create__c = 'Only Grievance Notes',
                Type = 'Customer',
                AccountNumber = '0001',
                Default_Account_Email_Address__c = 'mr@test.com',
                Email_Template_1__c = 'Grievance Created - General',
                Email_Recipients_1__c = 'Default Account Email Address',
                Automatic_Event_1__c = 'Submitted',
                Email_Template_2__c = 'Grievance Created - MCCFL',
                Email_Recipients_2__c = 'Submitting Contact',
                Automatic_Event_2__c = 'Resolved',
                Email_Template_3__c = 'Resolution - Detailed',
                Email_Recipients_3__c = 'Default Account Email Address',
                Automatic_Event_3__c = 'Follow Up Requested',
                Email_Template_4__c = 'Resolution - MCCVA',
                Email_Recipients_4__c = 'Submitting Contact',
                Automatic_Event_4__c = 'Submitted',
                Email_Template_5__c = 'Resolution - General',
                Email_Recipients_5__c = 'Static Account Email Group',
                Automatic_Event_5__c = 'Follow Up Completed',
                Complaint_Category__c = true,
                Letter_of_Inquiry_Category__c = true,
                Agent_Issue_Subcategory__c = true,
                Driver_Issue_Subcategory__c = true,
                ALS_Service_Mode__c = true,
                BLS_Service_Mode__c = true,
                General_Priority_Days__c = 4,
                Expedited_Priority_Days__c = 2
        );
        insert a;
        Account a2 = new Account(
                Name = 'Test Account 2',
                RecordTypeId = aRecordType,
                Call_Center_Can_Create__c = 'Only Grievance Notes',
                Type = 'Customer',
                AccountNumber = '0002',
                Default_Account_Email_Address__c = 'mr1@test1.com',
                Complaint_Category__c = true,
                Quality_of_Care_Concern_Category__c = true,
                Agent_Issue_Subcategory__c = true,
                Late_Pickup_Subcategory__c = true,
                ALS_Service_Mode__c = true,
                BLS_Service_Mode__c = true,
                Wheelchair_Service_Mode__c = true,
                General_Priority_Days__c = 6,
                Expedited_Priority_Days__c = 3
        );
        insert a2;
        a2.Name = 'Testing Account 2';
        AccountTriggerHandler.firstRun = true;
        update a2;
        Contact cont = new Contact(
                LastName = 'Jones',
                Email = 'test@tester.com',
                Account = a,
                Member_of_Static_Account_Email_Group__c = true
        );
        insert cont;
        Id CaseGN = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Grievance Note').getRecordTypeId();
        Case c = new Case (
                RecordTypeId = CaseGN,
                AccountId = a.Id,
                ContactId = cont.Id,
                Status = 'Submitted',
                Category__c = 'Complaint',
                Subcategory__c = 'Agent Issue',
                Service_Mode__c = 'ALS',
                Member_Name__c = 'Johnny',
                Member_ID__c = '1234',
                Priority = 'General'
        );
        Case c2 = new Case (
                RecordTypeId = CaseGN,
                AccountId = a2.Id,
                ContactId = cont.Id,
                Status = 'Submitted',
                Category__c = 'Quality of Care Concern',
                Subcategory__c = 'Agent Issue',
                Service_Mode__c = 'BLS',
                Member_Name__c = 'Janey',
                Member_ID__c = '123456',
                Priority = 'Expedited'
        );


        //Begin testing on insert scenario
        test.startTest();
        insert c;
        insert c2;
        Case testCase = [SELECT Id, Time_with_Support__c FROM Case WHERE Id =: c.Id];
        System.assertEquals(0.00, testCase.Time_with_Support__c);


        Case upC = [SELECT Id, Status, Follow_Up_Comments__c FROM Case WHERE Id =: c.Id LIMIT 1];
        Case upC2 = [SELECT Id, Status, Follow_Up_Comments__c FROM Case WHERE Id =: c2.Id LIMIT 1];
        CaseTriggerHandler.firstRun = true;
        upC.Status = 'In Progress';
        update upC;
        upC2.Status = 'In Progress';
        update upC2;

        System.debug('CaseTrigger_Test::: after first update');
        upC.Subject = 'tester';
        CaseTriggerHandler.firstRun = true;
        update upC;
        upC.Status = 'Resolved';
        CaseTriggerHandler.firstRun = true;
        update upC;
        upC2.Status = 'Resolved';
        CaseTriggerHandler.firstRun = true;
        update upC2;
        upC.Status = 'Follow Up Requested';
        upC.Follow_Up_Comments__c = 'Customer was not satisfied with Resolution.';
        CaseTriggerHandler.firstRun = true;
        update upC;
        upC.Status = 'In Progress';
        CaseTriggerHandler.firstRun = true;
        update upC;
        upC.Status = 'Pending Information';
        CaseTriggerHandler.firstRun = true;
        update upC;
        upC.Status = 'In Progress';
        CaseTriggerHandler.firstRun = true;
        update upC;
        upC.Status = 'Follow Up Resolved';
        CaseTriggerHandler.firstRun = true;
        update upC;
        test.stopTest();
        System.debug('CaseTrigger_Test::: tests complete');


    } //public static testmethod void insertCase()


}