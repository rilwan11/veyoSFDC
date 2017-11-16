/**
 * Created by krizia on 11/11/17.
 */
@isTest
public with sharing class veyoCallCenterCaseSubmission_Test {

    /**
     * Krizia: Test call center landing page (veyoCallCenterCaseSubmission.page) with controller of (veyoCallCenterCaseSubmissionController)
     */
    public static testMethod void testVeyoCallCenterCaseSubmissionController() {

        //Insert Test data
        Id aRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId();
        Account a = new Account(
                Name = 'Test Account',
                RecordTypeId = aRecordType,
                Call_Center_Can_Create__c = 'Only Grievance Notes',
                Type = 'Customer',
                AccountNumber = '0001',
                Default_Account_Email_Address__c = 'mr@t.com',
                Complaint_Category__c = true,
                Letter_of_Inquiry_Category__c = true,
                Quality_of_Care_Concern_Category__c = true,
                Agent_Issue_Subcategory__c = true,
                Driver_Issue_Subcategory__c = true,
                Damage_Injury_Subcategory__c = true,
                Early_Arrival_Subcategory__c = true,
                Late_Pickup_Subcategory__c = true,
                Missed_Pickup_Subcategory__c = true,
                Safety_Concern_Subcategory__c = true,
                Scheduling_Error_Subcategory__c = true,
                Technical_Issue_Subcategory__c = true,
                Vehicle_Issue_Subcategory__c = true,
                Missed_Pickup_A_Leg_Subcategory__c = true,
                Missed_Pickup_B_Leg_Subcategory__c = true,
                Late_Pickup_A_Leg_Subcategory__c = true,
                Late_Pickup_B_Leg_Subcategory__c = true,
                ALS_Service_Mode__c = true,
                BLS_Service_Mode__c = true,
                Ambulatory_Service_Mode__c = true,
                Wheelchair_Service_Mode__c = true,
                Bariatric_Wheelchair_Service_Mode__c = true,
                Public_Transportation_Service_Mode__c = true,
                Mileage_Reimbursement_Service_Mode__c = true,
                General_Priority_Days__c = 4,
                Expedited_Priority_Days__c = 2
        );
        insert a;
        Contact c = new Contact(
                LastName = 'Testy',
                Email = 'test@test.com',
                Account = a
        );
        insert c;

        // Add parameters to page URL
        Test.startTest();
        PageReference pageRef = Page.veyoCallCenterCaseSubmission;
        Test.setCurrentPage(pageRef);

        veyoCallCenterCaseSubmissionController controller = new veyoCallCenterCaseSubmissionController();
        PageReference p = controller.save();
        controller.m_case.accountId = a.Id;
        system.debug(controller.m_case);
        List<SelectOption> options = controller.getCaseSubmissionTypes();
        PageReference p1 = controller.save();
        system.debug('this is the message 2 '+ ApexPages.getMessages());
        controller.caseType = 'Grievance Note';
        PageReference p2 = controller.save();
        system.debug('this is the message 3 '+ ApexPages.getMessages());
        controller.m_case.Member_Name__c = 'Johnny';
        ApexPages.currentPage().getParameters().put('Member ID', '11223344');
        ApexPages.currentPage().getParameters().put('Contact ID', c.Id);

        List<SelectOption> options2 = controller.getCategoryOptions();
        List<SelectOption> options3 = controller.getSubcategoryOptions();
        List<SelectOption> options4 = controller.getServiceModeOptions();

        system.assertNotEquals(null, options, 'The collection should be instantiated');
        system.assert(!options2.isEmpty(), 'The collection should be populated');
        system.assertNotEquals(null, options3, 'The collection should be instantiated');
        system.assert(!options4.isEmpty(), 'The collection should be populated');


        ApexPages.currentPage().getParameters().put('Category', 'Letter of Inquiry');
        ApexPages.currentPage().getParameters().put('Subcategory', 'Driver Issue');
        ApexPages.currentPage().getParameters().put('Service Mode', 'ALS');
        ApexPages.currentPage().getParameters().put('Priority', 'General');
     //   ApexPages.currentPage().getParameters().put('Trip Date', '11/11/2017');
        ApexPages.currentPage().getParameters().put('Contact Name', 'Testy');
        ApexPages.currentPage().getParameters().put('Service Mode', 'ALS');
        ApexPages.currentPage().getParameters().put('Priority', 'General');
        PageReference p3 = controller.save();
        test.stopTest();


        // Verify that the success page displays
        //    String nextPage = controller.save().getUrl();
    //    System.assertEquals('/apex/veyoCallCenterCaseSubmission', nextPage);
    } //public static testMethod void testCaseConfiguredPicklistsController()


}