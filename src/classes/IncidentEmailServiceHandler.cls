/**
 * Created by krizia on 10/17/17.
 */


global class IncidentEmailServiceHandler implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

        //Objects that should be referenced
        Account account;
        Contact contact;
        Incident__c incident;
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        System.debug('IncidentEmailServiceHandler::: handleInboundEmail');

        try {
            System.debug('IncidentEmailServiceHandler::: handleInboundEmail:: TRY');
            // Look for INCIDENT whose name is in the subject
            string subj = email.subject;
            Integer len = subj.length();
            Integer index = len - 12;
            subj = subj.substring(index,subj.length());
            system.debug(subj);


            if ([SELECT count() FROM Incident__c WHERE Name =: subj] == 0) {
                System.debug('IncidentEmailServiceHandler::: handleInboundEmail:: IF');
                //**Handle case of INCIDENT not existing**//
                result.success = false;
                result.message = 'Invalid Incident Number, unable to process request.';
                return result;
            } else {
                System.debug('IncidentEmailServiceHandler::: handleInboundEmail:: ELSE ');
                //Case where INCIDENT exists
                incident = [SELECT Id, Account__c, Contact__c, RecordTypeId, Status__c, CreatedById
                                FROM Incident__c
                                WHERE Name =: email.subject
                                LIMIT 1];
                System.debug('IncidentEmailServiceHandler::: handleInboundEmail:: Incident: ' + string.valueOf(incident));

                //Turn email


/*
                // Turn email body into NOTE
                Note note = new Note();
                System.debug('IncidentEmailServiceHandler::: handleInboundEmail:: creating new Note');
                if (email.fromName != null) {
                    note.Title = email.fromName + ' (' + DateTime.now() + ')';
                }
                if (email.plainTextBody != null) {
                    note.Body = email.plainTextBody;
                }
                note.ParentId = incident.Id;
                if (note.Title != null) {
                    insert note;
                }
*/

                // Save attachments, if any
                List<Attachment> attachList = new List<Attachment>();
                System.debug('IncidentEmailServiceHandler::: handleInboundEmail:: check for attachments');
            //    System.debug(string.valueOf(email.textAttachments.size()));
                if (email.textAttachments == null) {
                    System.debug('IncidentEmailServiceHandler::: handleInboundEmail:: NO text attachments');
                }
                else {
                    for (Messaging.Inboundemail.TextAttachment tAttachment : email.textAttachments) {
                        System.debug('textAttachments');
                        Attachment attachment = new Attachment();
                        attachment.Name = tAttachment.fileName;
                        System.debug(attachment.Name);
                        attachment.Body = Blob.valueOf(tAttachment.body);
                        System.debug(attachment.Body);
                        attachment.ContentType = 'File';
                        System.debug(attachment.ContentType);
                        attachment.ParentId = incident.Id;
                        System.debug(attachment.ParentId);
                        attachList.add(attachment);
                    }
                    // Insert attachments, if any
                    if (attachList.size() > 0) {
                        insert attachList;
                        System.debug('IncidentEmailServiceHandler::: handleInboundEmail:: insert text attachments');
                    }
                }
                if (email.binaryAttachments == null) {
                    System.debug('IncidentEmailServiceHandler::: handleInboundEmail:: NO binary attachments');
                }
                else {
                    List<Attachment> attachList2 = new List<Attachment>();
                    for (Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {
                        System.debug('binaryAttachments');
                        Attachment attachment = new Attachment();
                        attachment.Name = bAttachment.fileName;
                        attachment.Body = bAttachment.body;
                        attachment.ParentId = incident.Id;
                        attachList2.add(attachment);
                    }
                    // Insert attachments, if any
                    if (attachList2.size() > 0) {
                        insert attachList2;
                        System.debug('IncidentEmailServiceHandler::: handleInboundEmail:: insert binary attachments');
                    }
                }


                result.success = true;
                System.debug('IncidentEmailServiceHandler::: handleInboundEmail:: result success - ' + string.valueOf(result.success));
            }
        }
        catch (Exception e) {
            System.debug(e);
            result.success = false;
            result.message = 'Unable to process request.';
        }

        return result;
    } //global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope)

} //global class IncidentEmailServiceHandler implements Messaging.InboundEmailHandler