/**
 * Created by krizia on 10/20/17.
 */
@isTest
public with sharing class CaseTrigger_Test {

    public static testmethod void insertCase() {
        Account a = new Account(
                Name = 'Test Account'
        );
        insert a;
        Contact cont = new Contact(
                LastName = 'Jones',
                Email = 'test@tester.com',
                Account = a
        );
        insert cont;
        Case c = new Case (
                AccountId = a.Id,
                ContactId = cont.Id,
                Status = 'Submitted'
        );

        //Begin testing on insert scenario
        test.startTest();
        insert c;
        Case testCase = [SELECT Id, Time_with_Support__c FROM Case WHERE Id =: c.Id];
        System.assertEquals(0.00, testCase.Time_with_Support__c);


        Case upC = [SELECT Id, Status, Follow_Up_Comments__c FROM Case WHERE Id =: c.Id LIMIT 1];
        CaseTriggerHandler.firstRun = true;
        upC.Status = 'In Progress';
        update upC;
        System.debug('CaseTrigger_Test::: after first update');
        upC.Subject = 'tester';
        CaseTriggerHandler.firstRun = true;
        update upC;
        upC.Status = 'Resolved';
        CaseTriggerHandler.firstRun = true;
        update upC;
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