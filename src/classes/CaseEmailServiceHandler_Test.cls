/**
 * Created on 10/19/17.
 */


@IsTest
private class CaseEmailServiceHandler_Test {

    static testMethod void testBehavior() {
        //Create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Messaging.InboundEmail email2 = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env2 = new Messaging.InboundEnvelope();

        //Create a new Account, Contact, and Incident for testing
        Id aRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId();
        Account a = new Account(
                Name = 'Test Account',
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
        Contact c = new Contact(
                LastName = 'Tester',
                Email = 'tester@tester.com',
                AccountId = a.Id
        );
        insert c;
        Id CaseGN = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Grievance Note').getRecordTypeId();
        Case testCase = new Case(
                RecordTypeId = CaseGN,
                AccountId = a.Id,
                ContactId = c.Id,
                Status = 'Submitted'
        );
        insert testCase;
        testCase = [SELECT Id, CaseNumber, Status FROM Case WHERE Id =: testCase.Id LIMIT 1];
        System.debug('CaseEmailServiceHandler_Test::: ' + string.valueOf(testCase));

        //Setup the data for the email
        email.subject = 'This is the Grievance: ' + string.valueOf(testCase.CaseNumber);
        email.fromName = c.LastName;
        email.fromAddress = c.Email;
        email.plainTextBody = 'I am a test';
        env.fromAddress = c.Email;
        email2.subject = 'does not exist';
        email2.fromName = c.LastName;
        email2.fromAddress = c.Email;
        email2.plainTextBody = 'I am a test that will not work';
        env2.fromAddress = c.Email;

        //Add an attachment
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfile.txt';
        attachment.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
        Messaging.InboundEmail.TextAttachment attachment2 = new Messaging.InboundEmail.TextAttachment();
        attachment2.body = 'my second attachment text';
        attachment2.fileName = 'textfile2.txt';
        attachment2.mimeTypeSubType = 'text/plain';
        email.textAttachments = new Messaging.inboundEmail.TextAttachment[] { attachment2 };


        CaseEmailServiceHandler emailCase = new CaseEmailServiceHandler();
        System.debug('CaseEmailServiceHandler_Test  ' + string.valueOf(c));
        //Call the email service class and test it with the data in the testMethod
        test.startTest();
        Messaging.InboundEmailResult r1 = emailCase.handleInboundEmail(email, env);
        testCase.Status = 'Pending Information';
        update testCase;
        Messaging.InboundEmailResult r2 = emailCase.handleInboundEmail(email2, env2);
        test.stopTest();
        System.assertEquals(true, r1.success);
        System.assertEquals(false, r2.success);
    } //static testMethod void testBehavior()
} //@IsTest private class CaseEmailServiceHandler_Test