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
        Contact defaultEmail = new Contact(
                LastName = 'Default Account Email Address',
                Email = a.Default_Account_Email_Address__c
        );
        insert defaultEmail;
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


        PageReference pageRef = Page.SendCaseEmail;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('a', a.Id);
        ApexPages.currentPage().getParameters().put('Id', c.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(c);
        SendCaseEmailController controller = new SendCaseEmailController(stdController);


        // Add parameters to page URL
        test.startTest();
        List<SelectOption> options = controller.getEmailTemplates();
        controller.templateSelection();
        ApexPages.currentPage().getParameters().put('Email Template', '');
        controller.emailTemplateSelection = '';
        controller.renderEmail();
        System.debug(ApexPages.getMessages());

        controller.emailTemplateSelection = 'Grievance Investigation - Driver Statement';
        controller.templateSelection();
        controller.renderEmail();
        System.debug(ApexPages.getMessages());
        controller.directEmail1 = 'incorrect';
        controller.emailPreSend();
        System.debug(ApexPages.getMessages());
        controller.directEmail1 = cont.Email;
        controller.directEmail2 = 'uifeowj@uiof.com';
        controller.directEmail3 = 'fewio@jjj.com';
        controller.directEmail4 = 'uifw@iii.com';
        controller.emailPreSend();
        controller.onSend();
        System.debug(ApexPages.getMessages());
        controller.emailTemplateSelection = 'Request Information from Member';
        controller.templateSelection();
        controller.emailPreSend();
        controller.onSend();
        System.debug(ApexPages.getMessages());
        controller.emailTemplateSelection = 'Internal Information Request - Call Center General';
        controller.templateSelection();
        controller.additionalText = 'just something I want to say';
        controller.emailPreSend();
        controller.onSend();
        System.debug(ApexPages.getMessages());
        test.stopTest();
        

    } //public static testMethod void testSendCaseEmailController()

}