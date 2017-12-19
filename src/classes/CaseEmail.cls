/**
 * Created on 10/19/17.
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
        EmailServicesAddress domainName = [SELECT EmailDomainName FROM EmailServicesAddress WHERE LocalPart = 'caseemailservice'];
        String caseEmailService = 'caseemailservice@' + string.valueOf(domainName.EmailDomainName);
   //     String caseEmailService = 'caseemailservice@1vh6z3r1ljiho3ljw45ail1ejcn7pqyyn02a6g55b89opq918s.5b-z2auau.cs52.apex.sandbox.salesforce.com';
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



    public static Boolean sendEmailFromModalWithAttachments(Case c, String[] toRecipients, Id TargetObjId, String templateString, List<Messaging.EmailFileAttachment> efa, List<ContentDocumentLink> cdlList) {

        //Common variables
        List<Messaging.SingleEmailMessage> allEmails = new List<Messaging.SingleEmailMessage>();
        Schema.sObjectType entityType = Case.getSobjectType();
        ID orgWideEmailId = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Veyo Case Management' LIMIT 1].Id;
        EmailServicesAddress domainName = [SELECT EmailDomainName FROM EmailServicesAddress WHERE LocalPart = 'caseemailservice'];
        String caseEmailService = 'caseemailservice@' + string.valueOf(domainName.EmailDomainName);
        Boolean saveAsActivity = true;
        Id whatId = c.Id;
        Attachment[] attachList;
        Id templateId;

        //Get the specified Email Template
        try {
            templateId = [SELECT Id FROM EmailTemplate WHERE Name =: TemplateString].Id;
        } catch (Exception e) {
            System.debug('CaseEmail::: Exception in sendEmailFromModalWithAttachments');
            //   throw new UtilException ('[U-03] Unable to locate EmailTemplate using name: ' + templateApiName + ' refer to Setup | Communications Templates ' + templateApiName);
        }
        System.debug('CaseEmail::: sendEmailFromModalWithAttachments templateId: ' + string.valueOf(templateId));



        //Add ContentDocument attachments if there are any
        System.debug('CaseEmail::: sendEmailFromModalWithAttachments:: efa: ' + string.valueOf(efa));
        System.debug('CaseEmail::: sendEmailFromModalWithAttachments:: cdlList: ' + string.valueOf(cdlList));
        if (cdlList.size() > 0) {
            Set<Id> contentDocIds = new Set<Id>();
            for(ContentDocumentLink contentDocLink : cdlList) {
                contentDocIds.add(contentDocLink.ContentDocumentId);
            }
            List<Id> contentDocIdList = new List<Id>(contentDocIds);

            // Get the actual files
            List<ContentVersion> contentVersions = new List<ContentVersion>();
            contentVersions = [SELECT Id, ContentUrl, Title, FileType, VersionData, isLatest, ContentDocumentId
                FROM ContentVersion
                WHERE ContentDocumentId IN :contentDocIdList  AND  IsLatest = True ];

            //add to emailAttachments
            List<Attachment> attachmentList = new List<Attachment>();
            for (ContentVersion con : contentVersions) {
                Attachment at = new Attachment();
                at.Body = con.VersionData;
                at.Name = con.Title;
                at.ContentType = 'File';
                at.ParentId = c.Id;
                attachmentList.add(at);
            }
            insert attachmentList;
            for (Attachment att : attachmentList) {
                Messaging.EmailFileAttachment attachME = new Messaging.EmailFileAttachment();

                attachME.setBody(att.Body);
                attachME.setFileName(att.Name);

                efa.add(attachME);
            }

            delete attachmentList;
        }
        System.debug('CaseEmail::: sendEmailFromModalWithAttachments:: efa before sending: ' + string.valueOf(efa));



        //Compose Email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        System.debug('!! CaseEmail::: sendEmailFromModalWithAttachments:: toRecipients: ' + string.valueOf(toRecipients));
        email.setToAddresses(toRecipients);
        email.setOrgWideEmailAddressId(orgWideEmailId);
        email.setReplyTo(caseEmailService);
        email.setTemplateId(templateId);
        email.setTargetObjectId(targetObjId);
        email.setWhatId(whatId);
        email.setFileAttachments(efa);
        email.setSaveAsActivity(saveAsActivity);      // save email as activity on the targetObjId (i.e. Case). Note activity can't be saved on Users

        System.debug(LoggingLevel.INFO, '** entered sendEmailFromModalWithAttachments, to:' + toRecipients + 'templateId:' + templateId + ' targetObjId:' + targetObjId + ' whatId:' + whatId + ' orgWideEmailId: ' + orgWideEmailId);



        //Now send email
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            System.debug('CaseEmail::: sendEmailFromModalWithAttachments successful');
            return(true);
            //return;
        } catch (EmailException e) {
            System.debug('CaseEmail::: Exception in sendEmailFromModalWithAttachments2');
            System.debug(e);
            return(false);
        }

    } //public static Boolean sendEmailFromModalWithAttachments(Case c, String[] toRecipients, Id TargetObjId, String templateString, List<Messaging.EmailFileAttachment> efa)


} //public with sharing class CaseEmail