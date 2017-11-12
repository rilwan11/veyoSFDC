/**
 * Created by krizia on 11/11/17.
 */
@isTest
public with sharing class SendCaseEmailController_Test {

    /**
 * Krizia: Test Grievance detail page popup for sending emails (SendCaseEmail.page) with controller of (SendCaseEmailController)
 */
    public static testMethod void testSendCaseEmailController() {

        Id aRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId();
        Account a = new Account(
                Name = 'Test Account 2',
                RecordTypeId = aRecordType,
                Call_Center_Can_Create__c = 'Only Grievance Notes',
                Type = 'Customer',
                AccountNumber = '0002',
                Default_Account_Email_Address__c = 'mr@test.com',
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
                Status = 'Submitted',
                Member_Name__c = 'Johnny',
                Member_ID__c = '1234',
                Priority = 'General'
        );
        insert c;


        ApexPages.StandardController stdController = new ApexPages.StandardController(c);
        SendCaseEmailController controller = new SendCaseEmailController(stdController);
        PageReference pageRef = Page.CaseDetailPage;
        Test.setCurrentPage(pageRef);

        //NEED TO BE ABLE TO QUERY THE CASE/ACCOUNT in the actual Controller for this to work

        // Add parameters to page URL
        List<SelectOption> options = controller.getEmailTemplates();
        ApexPages.currentPage().getParameters().put('Email Template', '');
        controller.renderEmail();
        controller.onSend();
        // controller.templateSelection();
        ApexPages.currentPage().getParameters().put('Email Template', 'HCA/HCIC: Grievance Resolved - 1');
        controller.renderEmail();
        controller.onSend();
        ApexPages.currentPage().getParameters().put('Email Template', 'Grievance Investigation - Driver Statement');
        controller.renderEmail();
        ApexPages.currentPage().getParameters().put('Additional Email Text', 'just something I want to say');
        controller.renderEmail();
        controller.onSend();


    } //public static testMethod void testSendCaseEmailController()

}