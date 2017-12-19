/**
 * Created on 11/11/17.
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
        Account a2 = new Account(
                Name = 'Test Account 2',
                RecordTypeId = aRecordType,
                Call_Center_Can_Create__c = 'Only First Call Resolutions',
                Type = 'Customer',
                AccountNumber = '0002',
                Default_Account_Email_Address__c = 'mr@test.com',
                Complaint_Category__c = true,
                Letter_of_Inquiry_Category__c = true,
                Quality_of_Care_Concern_Category__c = true,
                Agent_Issue_Subcategory__c = true,
                Driver_Issue_Subcategory__c = true,
                Damage_Injury_Subcategory__c = true,
                Early_Arrival_Subcategory__c = true,
                Late_Pickup_Subcategory__c = true,
                Ambulatory_Service_Mode__c = true,
                Wheelchair_Service_Mode__c = true,
                Bariatric_Wheelchair_Service_Mode__c = true,
                General_Priority_Days__c = 4,
                Expedited_Priority_Days__c = 2
        );
        insert a2;
        Account a3 = new Account(
                Name = 'Test Account 3',
                RecordTypeId = aRecordType,
                Call_Center_Can_Create__c = 'Grievance Notes and First Call Resolutions',
                Type = 'Customer',
                AccountNumber = '0003',
                Default_Account_Email_Address__c = 'mr@test123.com',
                Complaint_Category__c = true,
                Letter_of_Inquiry_Category__c = true,
                Quality_of_Care_Concern_Category__c = true,
                Agent_Issue_Subcategory__c = true,
                Driver_Issue_Subcategory__c = true,
                Damage_Injury_Subcategory__c = true,
                Wheelchair_Service_Mode__c = true,
                Bariatric_Wheelchair_Service_Mode__c = true,
                General_Priority_Days__c = 6,
                Expedited_Priority_Days__c = 1
        );
        insert a3;
        Account a4 = new Account(
                Name = 'Test Account 4',
                RecordTypeId = aRecordType,
                Call_Center_Can_Create__c = 'Neither',
                Type = 'Customer',
                AccountNumber = '0004',
                Default_Account_Email_Address__c = 'mr123@test123.com',
                Complaint_Category__c = true,
                Letter_of_Inquiry_Category__c = true,
                Quality_of_Care_Concern_Category__c = true,
                Agent_Issue_Subcategory__c = true,
                Driver_Issue_Subcategory__c = true,
                Damage_Injury_Subcategory__c = true,
                Wheelchair_Service_Mode__c = true,
                Bariatric_Wheelchair_Service_Mode__c = true,
                General_Priority_Days__c = 10,
                Expedited_Priority_Days__c = 3
        );
        insert a4;
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

        controller.m_case.AccountId = a4.Id;
        Boolean err1 = controller.getDisplayAccountErrorMessage();
        System.debug(controller.getaccountErrorMessage());
        system.debug(controller.m_case);
        List<SelectOption> options = controller.getCaseSubmissionTypes();
        PageReference p1 = controller.save();
        system.debug('this is the message from a4 '+ ApexPages.getMessages());
        controller.m_case.AccountId = a3.Id;
        Boolean err2 = controller.getDisplayAccountErrorMessage();
        System.debug(controller.getaccountErrorMessage());
        system.debug(controller.m_case);
        List<SelectOption> options2 = controller.getCaseSubmissionTypes();
        PageReference p2 = controller.save();
        system.debug('this is the message from a3 '+ ApexPages.getMessages());
        controller.m_case.AccountId = a2.Id;
        Boolean err3 = controller.getDisplayAccountErrorMessage();
        System.debug(controller.getaccountErrorMessage());
        system.debug(controller.m_case);
        List<SelectOption> options3 = controller.getCaseSubmissionTypes();
        PageReference p3 = controller.save();
        system.debug('this is the message from a2 '+ ApexPages.getMessages());



        controller.m_case.accountId = a.Id;
        system.debug(controller.m_case);
        List<SelectOption> options4 = controller.getCaseSubmissionTypes();
        PageReference p4 = controller.save();
        system.debug('this is the message 2 '+ ApexPages.getMessages());
        controller.caseType = 'Grievance Note';
        PageReference p5 = controller.save();
        system.debug('this is the message 3 '+ ApexPages.getMessages());
        controller.m_case.Member_Name__c = 'Johnny';
        ApexPages.currentPage().getParameters().put('Member ID', '11223344');
    //    ApexPages.currentPage().getParameters().put('Contact ID', c.Id);

        List<SelectOption> options5 = controller.getCategoryOptions();
        List<SelectOption> options6 = controller.getSubcategoryOptions();
        List<SelectOption> options7 = controller.getServiceModeOptions();

        system.assertNotEquals(null, options, 'The collection should be instantiated');
        system.assert(!options2.isEmpty(), 'The collection should be populated');
        system.assertNotEquals(null, options3, 'The collection should be instantiated');
        system.assert(!options4.isEmpty(), 'The collection should be populated');


        ApexPages.currentPage().getParameters().put('Category', 'Letter of Inquiry');
        ApexPages.currentPage().getParameters().put('Subcategory', 'Driver Issue');
        ApexPages.currentPage().getParameters().put('Service Mode', 'ALS');
        ApexPages.currentPage().getParameters().put('Priority', 'General');
     //   ApexPages.currentPage().getParameters().put('Trip Date', '11/11/2017');
        PageReference p6 = controller.save();
        test.stopTest();


        // Verify that the success page displays
        //    String nextPage = controller.save().getUrl();
    //    System.assertEquals('/apex/veyoCallCenterCaseSubmission', nextPage);
    } //public static testMethod void testCaseConfiguredPicklistsController()


}