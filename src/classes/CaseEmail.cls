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



} //public with sharing class CaseEmail