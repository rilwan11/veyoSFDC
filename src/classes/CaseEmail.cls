/**
 * Created by krizia on 10/19/17.
 * Individual methods for each type of outbound email from the Case object (Grievance Note)
 */
//Handler for all outgoing Email from an Case (Grievance Note / First Call Resolution)

global class CaseEmail {

    /**
     * Krizia: TEST - individual method for when alerting the Submitter that the Case (Grievance Note) has been filed
     */
    public static Boolean sendEmailFromModal(Case c, String[] toRecipients, Id TargetObjId, String templateString) {

        //Common variables
        List<Messaging.SingleEmailMessage> allEmails = new List<Messaging.SingleEmailMessage>();
        Schema.sObjectType entityType = Case.getSobjectType();
        ID orgWideEmailId = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Veyo Case Management' LIMIT 1].Id;
        String caseEmailService = 'caseemailservice@1vh6z3r1ljiho3ljw45ail1ejcn7pqyyn02a6g55b89opq918s.5b-z2auau.cs52.apex.sandbox.salesforce.com';
        Boolean saveAsActivity = true;
        Id whatId = c.Id;
        Attachment[] attachList;
        Id templateId;
        //Get the specified Email Template
        try {
            templateId = [SELECT Id FROM EmailTemplate WHERE Name =: TemplateString].Id;
        } catch (Exception e) {
            System.debug('CaseEmail::: Exception in sendEmailFromModal');
            //   throw new UtilException ('[U-03] Unable to locate EmailTemplate using name: ' + templateApiName + ' refer to Setup | Communications Templates ' + templateApiName);
        }
        System.debug('CaseEmail::: sendEmailFromModal templateId: ' + string.valueOf(templateId));


        //Compose Email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        System.debug('!! CaseEmail::: sendEmailFromModal:: toRecipients: ' + string.valueOf(toRecipients));
        email.setToAddresses(toRecipients);
        email.setOrgWideEmailAddressId(orgWideEmailId);
        email.setReplyTo(caseEmailService);
        email.setTemplateId(templateId);
        email.setTargetObjectId(targetObjId);
        email.setWhatId(whatId);
        email.setSaveAsActivity(saveAsActivity);      // save email as activity on the targetObjId (i.e. Case). Note activity can't be saved on Users

        System.debug(LoggingLevel.INFO, '** entered sendEmailFromModal, to:' + toRecipients + 'templateId:' + templateId + ' targetObjId:' + targetObjId + ' whatId:' + whatId + ' orgWideEmailId: ' + orgWideEmailId);



        //Now send email
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            System.debug('CaseEmail::: sendEmailFromModal successful');
            return(true);
            //return;
        } catch (EmailException e) {
            System.debug('CaseEmail::: Exception in sendEmailFromModal2');
            System.debug(e);
            return(false);
        }

    } //public static Boolean sendEmailFromModal(Case c, String[] toRecipients, Id TargetObjId, String templateString)















    /**
     * Krizia: individual method for alerting MCCFL when a Grievance was Submitted. Same recipient every time.
     *
     */
    public static void sendMCCFLGNCreated1(List<Case> cases) {

        //Common variables
        List<Messaging.SingleEmailMessage> allEmails = new List<Messaging.SingleEmailMessage>();
    //    String templateApiName = 'Grievance_Created_1';
        Schema.sObjectType entityType = Case.getSobjectType();
        ID orgWideEmailId = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Veyo Case Management' LIMIT 1].Id;
        String caseEmailService = 'caseemailservice@1vh6z3r1ljiho3ljw45ail1ejcn7pqyyn02a6g55b89opq918s.5b-z2auau.cs52.apex.sandbox.salesforce.com';
        Boolean saveAsActivity = true;
        Id templateId;
        try {
            templateId = [SELECT Id FROM EmailTemplate WHERE Name = 'MCCFL Only: Grievance Created - 1'].Id;
        } catch (Exception e) {
            System.debug('CaseEmail::: Exception in sendMCCFLGNCreated1');
            //   throw new UtilException ('[U-03] Unable to locate EmailTemplate using name: ' + templateApiName + ' refer to Setup | Communications Templates ' + templateApiName);
        }
        System.debug('CaseEmail::: sendMCCFLGNCreated1 templateId: ' + string.valueOf(templateId));


        for (Case c : cases) {
            Id whatId = c.Id;
            String[] toRecipients = new List<String>();
            String MCCFLemail = '';
//**** NEED TO ADD EMAIL HERE
            System.debug(MCCFLemail);
            toRecipients.add(MCCFLemail);
            Attachment[] attachList;
            ID targetObjId = c.Id;


            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();


            email.setToAddresses(toRecipients);
            email.setOrgWideEmailAddressId(orgWideEmailId);
            email.setReplyTo(caseEmailService);
            email.setTemplateId(templateId);
            email.setTargetObjectId(targetObjId);
            email.setWhatId(whatId);
            email.setSaveAsActivity(saveAsActivity);      // save email as activity on the targetObjId (i.e. Case). Note activity can't be saved on Users

            System.debug(LoggingLevel.INFO, '** entered sendMCCFLGNCreated1, to:' + toRecipients + 'templateId:' + templateId + ' targetObjId:' + targetObjId + ' whatId:' + whatId + ' orgWideEmailId: ' + orgWideEmailId);
            allEmails.add(email);
        }

        //Now send all emails
        try {
            Messaging.Email[] sendEmails = new List<Messaging.Email>();
            for (Integer i = 0; i < allEmails.size(); i++) {
                sendEmails.add(allEmails.get(i));
            }
            Messaging.sendEmail(sendEmails);
            System.debug('CaseEmail::: sendMCCFLGNCreated1 successful');
            return;
        } catch (EmailException e) {
            System.debug('CaseEmail::: Exception in sendMCCFLGNCreated1-2');
            System.debug(e);
        }

    } //public static void sendMCCFLGNCreated1(List<Case> cases)


    /**
    * Krizia: individual method for when requesting information from the Driver
    */
    public static void sendDriverStatement(List<Case> cases) {

        //Common variables
        List<Messaging.SingleEmailMessage> allEmails = new List<Messaging.SingleEmailMessage>();
        //       String templateApiName = 'Test_Incoming_Email';
        Schema.sObjectType entityType = Case.getSobjectType();
        ID orgWideEmailId = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Veyo Case Management' LIMIT 1].Id;
        String caseEmailService = 'caseemailservice@1vh6z3r1ljiho3ljw45ail1ejcn7pqyyn02a6g55b89opq918s.5b-z2auau.cs52.apex.sandbox.salesforce.com';
        Boolean saveAsActivity = true;
        Id templateId;
        try {
            templateId = [SELECT Id FROM EmailTemplate WHERE Name = 'Grievance Investigation - Driver Statement'].Id;
        } catch (Exception e) {
            System.debug('CaseEmail::: Exception in sendDriverStatement');
            //   throw new UtilException ('[U-03] Unable to locate EmailTemplate using name: ' + templateApiName + ' refer to Setup | Communications Templates ' + templateApiName);
        }
        System.debug('CaseEmail::: sendDriverStatement templateId: ' + string.valueOf(templateId));

        Set<Id> contactIDs = new Set<Id>();
        for (Case c : cases) {
            contactIDs.add(c.ContactID);
        }
        Map<Id, Contact> contactsMap = new Map<Id, Contact>([SELECT Id, Email FROM Contact WHERE Id IN :contactIDs]);



        for (Case c : cases) {
            Id whatId = c.Id;
            String[] toRecipients = new List<String>();
            Contact caseContact;
            if (null != contactsMap.get(c.ContactId)) {
                caseContact = contactsMap.get(c.ContactId);
            }
            else {
                continue;
            }

            System.debug(caseContact.Email);
            toRecipients.add(caseContact.Email);
            Attachment[] attachList;
            ID targetObjId = caseContact.Id;


            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();


            email.setToAddresses(toRecipients);
            email.setOrgWideEmailAddressId(orgWideEmailId);
            email.setReplyTo(caseEmailService);
            email.setTemplateId(templateId);
            email.setTargetObjectId(targetObjId);
            email.setWhatId(whatId);
            email.setSaveAsActivity(saveAsActivity);      // save email as activity on the targetObjId (i.e. Case). Note activity can't be saved on Users

            System.debug(LoggingLevel.INFO, '** entered sendDriverStatement, to:' + toRecipients + 'templateId:' + templateId + ' targetObjId:' + targetObjId + ' whatId:' + whatId + ' orgWideEmailId: ' + orgWideEmailId);
            allEmails.add(email);
        }

        //Now send all emails
        try {
            Messaging.Email[] sendEmails = new List<Messaging.Email>();
            for (Integer i = 0; i < allEmails.size(); i++) {
                sendEmails.add(allEmails.get(i));
            }
            Messaging.sendEmail(sendEmails);
            System.debug('CaseEmail::: sendDriverStatement successful');
            return;
        } catch (EmailException e) {
            System.debug('CaseEmail::: Exception in sendDriverStatement');
            System.debug(e);
        }

    } //public static void sendDriverStatement(List<Case> cases)


    /**
    * Krizia: individual method for when requesting the Trip Log
    */
    public static void sendTripLog(List<Case> cases) {

        //Common variables
        List<Messaging.SingleEmailMessage> allEmails = new List<Messaging.SingleEmailMessage>();
        //       String templateApiName = 'Test_Incoming_Email';
        Schema.sObjectType entityType = Case.getSobjectType();
        ID orgWideEmailId = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Veyo Case Management' LIMIT 1].Id;
        String caseEmailService = 'caseemailservice@1vh6z3r1ljiho3ljw45ail1ejcn7pqyyn02a6g55b89opq918s.5b-z2auau.cs52.apex.sandbox.salesforce.com';
        Boolean saveAsActivity = true;
        Id templateId;
        try {
            templateId = [SELECT Id FROM EmailTemplate WHERE Name = 'Grievance Investigation - Trip Log'].Id;
        } catch (Exception e) {
            System.debug('CaseEmail::: Exception in sendTripLog');
            //   throw new UtilException ('[U-03] Unable to locate EmailTemplate using name: ' + templateApiName + ' refer to Setup | Communications Templates ' + templateApiName);
        }
        System.debug('CaseEmail::: sendTripLog templateId: ' + string.valueOf(templateId));

        Set<Id> contactIDs = new Set<Id>();
        for (Case c : cases) {
            contactIDs.add(c.ContactID);
        }
        Map<Id, Contact> contactsMap = new Map<Id, Contact>([SELECT Id, Email FROM Contact WHERE Id IN :contactIDs]);



        for (Case c : cases) {
            Id whatId = c.Id;
            String[] toRecipients = new List<String>();
            Contact caseContact;
            if (null != contactsMap.get(c.ContactId)) {
                caseContact = contactsMap.get(c.ContactId);
            }
            else {
                continue;
            }

            System.debug(caseContact.Email);
            toRecipients.add(caseContact.Email);
            Attachment[] attachList;
            ID targetObjId = caseContact.Id;


            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();


            email.setToAddresses(toRecipients);
            email.setOrgWideEmailAddressId(orgWideEmailId);
            email.setReplyTo(caseEmailService);
            email.setTemplateId(templateId);
            email.setTargetObjectId(targetObjId);
            email.setWhatId(whatId);
            email.setSaveAsActivity(saveAsActivity);      // save email as activity on the targetObjId (i.e. Case). Note activity can't be saved on Users

            System.debug(LoggingLevel.INFO, '** entered sendTripLog, to:' + toRecipients + 'templateId:' + templateId + ' targetObjId:' + targetObjId + ' whatId:' + whatId + ' orgWideEmailId: ' + orgWideEmailId);
            allEmails.add(email);
        }

        //Now send all emails
        try {
            Messaging.Email[] sendEmails = new List<Messaging.Email>();
            for (Integer i = 0; i < allEmails.size(); i++) {
                sendEmails.add(allEmails.get(i));
            }
            Messaging.sendEmail(sendEmails);
            System.debug('CaseEmail::: sendTripLog successful');
            return;
        } catch (EmailException e) {
            System.debug('CaseEmail::: Exception in sendTripLog');
            System.debug(e);
        }

    } //public static void sendTripLog(List<Case> cases)


    /**
    * Krizia: individual method for notifying HCA/HCIC GN Owner of Resolution
    */
    public static void sendResolved1(List<Case> cases) {

        //Common variables
        List<Messaging.SingleEmailMessage> allEmails = new List<Messaging.SingleEmailMessage>();
        //       String templateApiName = 'Test_Incoming_Email';
        Schema.sObjectType entityType = Case.getSobjectType();
        ID orgWideEmailId = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Veyo Case Management' LIMIT 1].Id;
        String caseEmailService = 'caseemailservice@1vh6z3r1ljiho3ljw45ail1ejcn7pqyyn02a6g55b89opq918s.5b-z2auau.cs52.apex.sandbox.salesforce.com';
        Boolean saveAsActivity = true;
        Id templateId;
        try {
            templateId = [SELECT Id FROM EmailTemplate WHERE Name = 'HCA/HCIC: Grievance Resolved - 1'].Id;
        } catch (Exception e) {
            System.debug('CaseEmail::: Exception in sendResolved1');
            //   throw new UtilException ('[U-03] Unable to locate EmailTemplate using name: ' + templateApiName + ' refer to Setup | Communications Templates ' + templateApiName);
        }
        System.debug('CaseEmail::: sendResolved1 templateId: ' + string.valueOf(templateId));



        for (Case c : cases) {
            Id whatId = c.Id;
            String[] toRecipients = new List<String>();

            System.debug(c.Owner.Email);
            toRecipients.add(c.Owner.Email);
            Attachment[] attachList;
            ID targetObjId = c.Id;


            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();


            email.setToAddresses(toRecipients);
            email.setOrgWideEmailAddressId(orgWideEmailId);
            email.setReplyTo(caseEmailService);
            email.setTemplateId(templateId);
            email.setTargetObjectId(targetObjId);
            email.setWhatId(whatId);
            email.setSaveAsActivity(saveAsActivity);      // save email as activity on the targetObjId (i.e. Case). Note activity can't be saved on Users

            System.debug(LoggingLevel.INFO, '** entered sendResolved1, to:' + toRecipients + 'templateId:' + templateId + ' targetObjId:' + targetObjId + ' whatId:' + whatId + ' orgWideEmailId: ' + orgWideEmailId);
            allEmails.add(email);
        }

        //Now send all emails
        try {
            Messaging.Email[] sendEmails = new List<Messaging.Email>();
            for (Integer i = 0; i < allEmails.size(); i++) {
                sendEmails.add(allEmails.get(i));
            }
            Messaging.sendEmail(sendEmails);
            System.debug('CaseEmail::: sendResolved1 successful');
            return;
        } catch (EmailException e) {
            System.debug('CaseEmail::: Exception in sendResolved1');
            System.debug(e);
        }

    } //public static void sendResolved1(List<Case> cases)


    /**
    * Krizia: individual method for notifying small group at MCCVA of Resolution
    */
    public static void sendResolved2(List<Case> cases) {

        //Common variables
        List<Messaging.SingleEmailMessage> allEmails = new List<Messaging.SingleEmailMessage>();
        //       String templateApiName = 'Test_Incoming_Email';
        Schema.sObjectType entityType = Case.getSobjectType();
        ID orgWideEmailId = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Veyo Case Management' LIMIT 1].Id;
        String caseEmailService = 'caseemailservice@1vh6z3r1ljiho3ljw45ail1ejcn7pqyyn02a6g55b89opq918s.5b-z2auau.cs52.apex.sandbox.salesforce.com';
        Boolean saveAsActivity = true;
        Id templateId;
        try {
            templateId = [SELECT Id FROM EmailTemplate WHERE Name = 'MCCVA: Grievance Resolved - 2'].Id;
        } catch (Exception e) {
            System.debug('CaseEmail::: Exception in sendResolved2');
            //   throw new UtilException ('[U-03] Unable to locate EmailTemplate using name: ' + templateApiName + ' refer to Setup | Communications Templates ' + templateApiName);
        }
        System.debug('CaseEmail::: sendResolved2 templateId: ' + string.valueOf(templateId));



        for (Case c : cases) {
            Id whatId = c.Id;
            String[] toRecipients = new List<String>();

            toRecipients.add(c.Owner.Email);
 //**** Add all Email recipients of small group at MCCVA here
            Attachment[] attachList;
            ID targetObjId = c.Id;


            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();


            email.setToAddresses(toRecipients);
            email.setOrgWideEmailAddressId(orgWideEmailId);
            email.setReplyTo(caseEmailService);
            email.setTemplateId(templateId);
            email.setTargetObjectId(targetObjId);
            email.setWhatId(whatId);
            email.setSaveAsActivity(saveAsActivity);      // save email as activity on the targetObjId (i.e. Case). Note activity can't be saved on Users

            System.debug(LoggingLevel.INFO, '** entered sendResolved2, to:' + toRecipients + 'templateId:' + templateId + ' targetObjId:' + targetObjId + ' whatId:' + whatId + ' orgWideEmailId: ' + orgWideEmailId);
            allEmails.add(email);
        }

        //Now send all emails
        try {
            Messaging.Email[] sendEmails = new List<Messaging.Email>();
            for (Integer i = 0; i < allEmails.size(); i++) {
                sendEmails.add(allEmails.get(i));
            }
            Messaging.sendEmail(sendEmails);
            System.debug('CaseEmail::: sendResolved2 successful');
            return;
        } catch (EmailException e) {
            System.debug('CaseEmail::: Exception in sendResolved2');
            System.debug(e);
        }

    } //public static void sendResolved2(List<Case> cases)


    /**
    * Krizia: individual method for notifying MCCFL of Resolution (same email address each time)
    */
    public static void sendResolved3(List<Case> cases) {

        //Common variables
        List<Messaging.SingleEmailMessage> allEmails = new List<Messaging.SingleEmailMessage>();
        //       String templateApiName = 'Test_Incoming_Email';
        Schema.sObjectType entityType = Case.getSobjectType();
        ID orgWideEmailId = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Veyo Case Management' LIMIT 1].Id;
        String caseEmailService = 'caseemailservice@1vh6z3r1ljiho3ljw45ail1ejcn7pqyyn02a6g55b89opq918s.5b-z2auau.cs52.apex.sandbox.salesforce.com';
        Boolean saveAsActivity = true;
        Id templateId;
        try {
            templateId = [SELECT Id FROM EmailTemplate WHERE Name = 'HCA/HCIC: Grievance Resolved - 1'].Id;
        } catch (Exception e) {
            System.debug('CaseEmail::: Exception in sendResolved3');
            //   throw new UtilException ('[U-03] Unable to locate EmailTemplate using name: ' + templateApiName + ' refer to Setup | Communications Templates ' + templateApiName);
        }
        System.debug('CaseEmail::: sendResolved3 templateId: ' + string.valueOf(templateId));



        for (Case c : cases) {
            Id whatId = c.Id;
            String[] toRecipients = new List<String>();
//**** add specific email address here
            System.debug(c.Owner.Email);
            toRecipients.add(c.Owner.Email);
            Attachment[] attachList;
            ID targetObjId = c.Id;


            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();


            email.setToAddresses(toRecipients);
            email.setOrgWideEmailAddressId(orgWideEmailId);
            email.setReplyTo(caseEmailService);
            email.setTemplateId(templateId);
            email.setTargetObjectId(targetObjId);
            email.setWhatId(whatId);
            email.setSaveAsActivity(saveAsActivity);      // save email as activity on the targetObjId (i.e. Case). Note activity can't be saved on Users

            System.debug(LoggingLevel.INFO, '** entered sendResolved3, to:' + toRecipients + 'templateId:' + templateId + ' targetObjId:' + targetObjId + ' whatId:' + whatId + ' orgWideEmailId: ' + orgWideEmailId);
            allEmails.add(email);
        }

        //Now send all emails
        try {
            Messaging.Email[] sendEmails = new List<Messaging.Email>();
            for (Integer i = 0; i < allEmails.size(); i++) {
                sendEmails.add(allEmails.get(i));
            }
            Messaging.sendEmail(sendEmails);
            System.debug('CaseEmail::: sendResolved3 successful');
            return;
        } catch (EmailException e) {
            System.debug('CaseEmail::: Exception in sendResolved3');
            System.debug(e);
        }

    } //public static void sendResolved3(List<Case> cases)















    /**
     * Krizia: individual method for when a Case (Grievance Note) has been closed (Status set to Resolved or Follow Up Completed)
     *
     * @param cases all incoming cases that triggered after update
     */
    public static void sendSummaryUponClose(List<Case> cases) {

        //Common variables
        List<Messaging.SingleEmailMessage> allEmails = new List<Messaging.SingleEmailMessage>();
        String templateApiName = 'Test_Incoming_Email';
        Schema.sObjectType entityType = Case.getSobjectType();
        ID orgWideEmailId = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Veyo Case Management' LIMIT 1].Id;
        String caseEmailService = 'caseemailservice@1vh6z3r1ljiho3ljw45ail1ejcn7pqyyn02a6g55b89opq918s.5b-z2auau.cs52.apex.sandbox.salesforce.com';
        Boolean saveAsActivity = true;
        Id templateId;
        try {
            templateId = [SELECT Id FROM EmailTemplate WHERE Name = 'Test Incoming Email'].id;
        } catch (Exception e) {
            System.debug('CaseEmail::: Exception in sendSummaryUponClose');
            //   throw new UtilException ('[U-03] Unable to locate EmailTemplate using name: ' + templateApiName + ' refer to Setup | Communications Templates ' + templateApiName);
        }
        System.debug('CaseEmail::: sendSummaryUponClose templateId: ' + string.valueOf(templateId));


        for (Case c : cases) {
            if (c.Status == 'Resolved' || c.Status == 'Follow Up Completed') { //Only send summary email upon Case being closed
                Id whatId = c.Id;
                String[] toRecipients = new List<String>();
                Contact cont = [SELECT Id, Email FROM Contact WHERE Id = :c.ContactId];
                System.debug(cont.Email);
                //     Case c = (Case)System.Trigger.newMap.get(cId);
                //     Contact contact = new Contact(Id = c.ContactId);
                toRecipients.add(cont.Email);
                Attachment[] attachList;
                ID targetObjId = cont.Id;


                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();


                email.setToAddresses(toRecipients);
                email.setorgWideEmailAddressId(orgWideEmailId);
                email.setReplyTo(caseEmailService);
                email.setTemplateId(templateId);
                email.setTargetObjectId(targetObjId);
                email.setWhatId(whatId);
                email.setSaveAsActivity(saveAsActivity);      // save email as activity on the targetObjId (i.e. Case). Note activity can't be saved on Users

                System.debug(LoggingLevel.INFO, '** entered sendSummaryUponClose, to:' + toRecipients + 'templateId:' + templateId + ' targetObjId:' + targetObjId + ' whatId:' + whatId + ' orgWideEmailId: ' + orgWideEmailId);
                allEmails.add(email);
            }
        }

        //Now send all emails
        try {
            Messaging.Email[] sendEmails = new List<Messaging.Email>();
            for (Integer i = 0; i < allEmails.size(); i++) {
                sendEmails.add(allEmails.get(i));
            }
            Messaging.sendEmail(sendEmails);
            System.debug('CaseEmail::: sendSummaryUponClose successful');
            return;
        } catch (EmailException e) {
            System.debug('CaseEmail::: Exception in sendSummaryUponClose2');
            System.debug(e);
        }

    } //public static void sendSummaryUponClose(List<Case> cases)

} //public with sharing class CaseEmail