/**
 * Created by krizia on 11/11/17.
 */
@isTest
public with sharing class CaseConfiguredPicklistsController_Test {

    /**
     * Krizia: Test Grievance detail page (CaseDetailPage.page) with controller of (CaseConfiguredPicklistsController)
     */
    public static testMethod void testCaseConfiguredPicklistsController() {

        Id aRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId();
        Account a = new Account(
                Name = 'Test Account 2',
                RecordTypeId = aRecordType,
                Call_Center_Can_Create__c = 'Only Grievance Notes',
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


        PageReference pageRef = Page.CaseDetailPage;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('Account', a.Id);
        ApexPages.currentPage().getParameters().put('Id', c.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(c);
        CaseConfiguredPicklistsController controller = new CaseConfiguredPicklistsController(stdController);

        //NEED TO BE ABLE TO QUERY THE CASE/ACCOUNT in the actual Controller for this to work

        // Add parameters to page URL
        test.startTest();
        List<SelectOption> options = controller.getCategoryOptions();
        List<SelectOption> options2 = controller.getSubcategoryOptions();
        List<SelectOption> options3 = controller.getServiceModeOptions();
        ApexPages.currentPage().getParameters().put('Category', 'Complaint');
        ApexPages.currentPage().getParameters().put('Subcategory', 'Agent Issue');
        ApexPages.currentPage().getParameters().put('Service Mode', 'ALS');
        ApexPages.currentPage().getParameters().put('Status', 'Follow Up Requested');
        controller.updatePicklists();
        ApexPages.currentPage().getParameters().put('Follow Up Comments', 'Should have just failed');
        controller.updatePicklists();
        test.stopTest();






    } //public static testMethod void testCaseConfiguredPicklistsController()


}