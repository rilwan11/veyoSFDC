/**
 * Created by krizia on 10/19/17.
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
        Account a = new Account(
                Name = 'Test Account'
        );
        insert a;
        Contact c = new Contact(
                LastName = 'Tester',
                Email = 'tester@tester.com',
                AccountId = a.Id
        );
        insert c;
        Case testCase = new Case(
                AccountId = a.Id,
                ContactId = c.Id,
                Status = 'Submitted'
        );
        insert testCase;
        testCase = [SELECT Id, CaseNumber FROM Case WHERE Id =: testCase.Id LIMIT 1];
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
        Messaging.InboundEmailResult r2 = emailCase.handleInboundEmail(email2, env2);
        test.stopTest();
        System.assertEquals(true, r1.success);
        System.assertEquals(false, r2.success);
    } //static testMethod void testBehavior()
} //@IsTest private class CaseEmailServiceHandler_Test