/**
 * Created on 10/19/17.
 * Handles all inbound emails to the CaseEmailService in order to add to corresponding Case (Grievance Note) Activities
 */

global class CaseEmailServiceHandler implements Messaging.InboundEmailHandler {

    /**
     * Krizia: Handle all inbound emails to CaseEmailService email address
     *      -This email is used as ReplyTo on all outbound emails from Cases (Grievance Notes)
     * @param email incoming email
     * @param envelope incoming envelope
     *
     * @return
     */
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

        //Objects that should be referenced
        Account account;
        //      Contact contact;
        Case c;
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        System.debug('CaseEmailServiceHandler::: handleInboundEmail');

        try {
            System.debug('CaseEmailServiceHandler::: handleInboundEmail:: TRY');
            // Look for INCIDENT whose name is in the subject
            //          contact = [SELECT Id, LastName, Email FROM Contact WHERE Email =: email.fromAddress LIMIT 1];
            //          System.debug('CaseEmailServiceHandler::: handleInboundEmail:: Contact: ' + string.valueOf(contact));
            string subj = email.subject;
            Integer len = subj.length();
            Integer index = len - 8;
            subj = subj.substring(index,subj.length());
            system.debug(subj);


            if ([SELECT count() FROM Case WHERE CaseNumber =: subj] == 0) {
                System.debug('CaseEmailServiceHandler::: handleInboundEmail:: IF');
                //**Handle case of Case not existing**//
                result.success = false;
                result.message = 'Invalid Case Number, unable to process request.';
                return result;
            }
            else {
                System.debug('CaseEmailServiceHandler::: handleInboundEmail:: ELSE ');
                //Case where Case exists
                c = [SELECT Id, AccountId, ContactId, Status, CreatedById, Open_Email_Response__c, OwnerId
                FROM Case
                WHERE CaseNumber =: subj
                LIMIT 1];
                System.debug('CaseEmailServiceHandler::: handleInboundEmail:: Incident: ' + string.valueOf(c));

                //Turn email into TASK
                Task t = new Task(
                        //  Owner = c.CreatedById,
                        Type = 'Email',
                        //  What = Case,
                        WhatId = c.Id
                        //  Who = contact.Id
                );
                System.debug('IncidentEmailServiceHandler::: handleInboundEmail:: creating new Task');
                if (email.fromName != null) {
                    t.Subject = 'Email Response from: ' + email.fromName + ' (' + DateTime.now() + ')';
                }
                else {
                    t.Subject = 'Email Response: ' + email.subject + ' (' + DateTime.now() + ')';
                }
                if (email.plainTextBody != null) {
                    t.Description = email.plainTextBody;
                }
                if (t.Subject != null) {
                    insert t;

                    Task t2 = [SELECT Id, OwnerId, Subject, Description FROM Task WHERE Subject =: t.Subject LIMIT 1];

                    // Save attachments, if any
                    List<Attachment> attachList = new List<Attachment>();
                    System.debug('CaseEmailServiceHandler::: handleInboundEmail:: check for attachments');
                    //    System.debug(string.valueOf(email.textAttachments.size()));
                    if (email.textAttachments == null) {
                        System.debug('CaseEmailServiceHandler::: handleInboundEmail:: NO text attachments');
                    }
                    else {
                        for (Messaging.Inboundemail.TextAttachment tAttachment : email.textAttachments) {
                            System.debug('textAttachments');
                         /*   Attachment attachment = new Attachment();
                            attachment.Name = tAttachment.fileName;
                            System.debug(attachment.Name);
                            attachment.Body = Blob.valueOf(tAttachment.body);
                            System.debug(attachment.Body);
                            attachment.ContentType = 'File';
                            System.debug(attachment.ContentType);
                            attachment.ParentId = c.Id;
                            attachment.Description = 'Attachment from Email Response';
                            System.debug(attachment.ParentId);
                            attachment.OwnerId = c.OwnerId;
                            attachList.add(attachment); */

                            //Activity attachment
                            Attachment attachment2 = new Attachment();
                            attachment2.Name = tAttachment.fileName;
                            attachment2.Body = Blob.valueOf(tAttachment.body);
                            attachment2.ContentType = 'File';
                            attachment2.ParentId = t2.Id;
                            attachment2.Description = 'Attachment from Email Response';
                            attachment2.OwnerId = t2.OwnerId;
                            attachList.add(attachment2);
                        }
                        // Insert attachments, if any
                        if (attachList.size() > 0) {
                            insert attachList;
                            System.debug('CaseEmailServiceHandler::: handleInboundEmail:: insert text attachments');
                        }
                    }
                    if (email.binaryAttachments == null) {
                        System.debug('CaseEmailServiceHandler::: handleInboundEmail:: NO binary attachments');
                    }
                    else {
                        List<Attachment> attachList2 = new List<Attachment>();
                        for (Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {
                         /*   System.debug('binaryAttachments');
                            Attachment attachment = new Attachment();
                            attachment.Name = bAttachment.fileName;
                            attachment.Body = bAttachment.body;
                            attachment.Description = 'Attachment from Email Response';
                            attachment.ParentId = c.Id;
                            attachment.OwnerId = c.OwnerId;
                            System.debug(attachment.Name);
                            attachList2.add(attachment); */

                            //Activity attachment
                            Attachment attachment2 = new Attachment();
                            attachment2.Name = bAttachment.fileName;
                            attachment2.Body = bAttachment.body;
                            attachment2.Description = 'Attachment from Email Response';
                            attachment2.ParentId = t2.Id;
                            attachment2.OwnerId = t2.OwnerId;
                            System.debug(attachment2.Name);
                            attachList2.add(attachment2);
                        }
                        // Insert attachments, if any
                        if (attachList2.size() > 0) {
                            insert attachList2;
                            System.debug('CaseEmailServiceHandler::: handleInboundEmail:: insert binary attachments');
                        }
                    }

                    result.success = true;
                    System.debug('CaseEmailServiceHandler::: handleInboundEmail:: result success - ' + string.valueOf(result.success));


                    //https://www.pivotaltracker.com/story/show/151818698
                    //Turn off Time with Customer clock and start up Time with Support clock by changing the Status to In Progress
                    if (c.Status == 'Pending Information') {
                        c.Status = 'In Progress';
                        //Will set off CaseTrigger to handle new Case Aging History
                        update c;
                    }
                    if (c.Open_Email_Response__c != true) { //Make it visible in list view that the Case/Grievance received an email
                        c.Open_Email_Response__c = true;
                        update c;
                    }
                }
            }
        }
        catch (Exception e) {
            System.debug(e);
            result.success = false;
            result.message = 'Unable to process request.';
        }

        return result;
    } //global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope)

} //global class CaseEmailServiceHandler implements Messaging.InboundEmailHandler