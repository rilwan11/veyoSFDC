/**
 * Created by krizia on 10/25/17.
 * Manage all logic behind the Sending of Emails from the UI
 */

public with sharing class SendCaseEmailController {
    public Id caseId;
    private final Case gn;
    private final Account a;
    public List<Case> caseList = new List<Case>();
    public String emailOutput { get; set; }
    public String emailTemplateSelection { get; set; }
    public boolean disabledAdditional { get; set; }
    public String additionalText { get; set; }
    public String input { get; set; }
    public String directEmail1 { get; set; }
    public String directEmail2 { get; set; }
    public String directEmail3 { get; set; }
    public String directEmail4 { get; set; }
    public boolean disabledEmail { get; set; }
    public boolean disabledButton { get; set; }
    public String emailSubject { get; set; }
    public List<String> allRecipients { get; set; }
    public String attachments { get; set; }
    public List<Attachment> queriedAttachments { get; set; }
    public List<ContentDocumentLink> queriedContentDocuments { get; set; }
    public List<ContentVersion> contentVersions { get; set; }

//    public Attachment doc { get; set; }

    //Email Template lists for checking in Preview and Send methods
    public List<String> directEmailAdditionalText { get; set; }
    public List<String> directEmailNOadditionalText { get; set; }
//    public List<String> additionalTextDefaultEmail { get; set; }
//    public List<String> defaultEmailOnly { get; set; }



    public sendCaseEmailController(ApexPages.StandardController stdController) {
        //gn = (Case)stdControl.getRecord();
        Id recordId = ApexPages.CurrentPage().getParameters().get('Id');
        System.debug('SendCaseEmailController::: recordId: ' + string.valueOf(recordId));
        gn = [SELECT Id, CaseNumber, ContactId, OwnerId, Additional_Email_Text__c, Email_Template__c, AccountId, ContactEmail
                FROM Case
                WHERE Id =: recordId
                LIMIT 1];
        a = [SELECT Id, Default_Account_Email_Address__c, Email_Template_1__c, Email_Template_2__c, Email_Template_3__c,
                Email_Template_4__c, Email_Template_5__c, Email_Recipients_1__c, Email_Recipients_2__c, Email_Recipients_3__c,
                Email_Recipients_4__c, Email_Recipients_5__c
                FROM Account
                WHERE Id =: gn.AccountId
                LIMIT 1];


        System.debug('SendCaseEmailController::: constructor:: gn: ' + string.valueOf(gn));
        disabledAdditional = false;

        System.currentPageReference().getParameters().put('addText','');
        emailTemplateSelection = '--None--';

        System.currentPageReference().getParameters().put('directEmail1', '');
        System.currentPageReference().getParameters().put('directEmail2', '');
        System.currentPageReference().getParameters().put('directEmail3', '');
        System.currentPageReference().getParameters().put('directEmail4', '');
        disabledEmail = false;

        disabledButton = true;

        //Tell them how to send an email
        ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.INFO, 'Please make sure to add all necessary input, then click the Preview button to check the Email before clicking Send. ');
        ApexPages.addMessage(errorMessage);
        System.debug(errorMessage);


        //Populate Email Template type lists
        directEmailAdditionalText = new List<String>();
        directEmailAdditionalText.add('KHB - Test Incoming Email');
        directEmailAdditionalText.add('Request Information from Member');
        directEmailAdditionalText.add('Request Information from Plan');
        directEmailAdditionalText.add('Request Information from Facility');
        directEmailAdditionalText.add('Grievance Investigation - Other');
        directEmailAdditionalText.add('Internal Information Request - Call Center General');
        directEmailAdditionalText.add('Internal Information Request - Call Center Call');
        directEmailAdditionalText.add('Internal Information Request - IDP Question');
        directEmailAdditionalText.add('Internal Information Request - IDP Suspension');
        directEmailAdditionalText.add('Remediation - Call Center Agent Retraining');
        directEmailAdditionalText.add('Remediation - Command Center Agent Retraining');
        directEmailAdditionalText.add('Remediation - IDP Retraining');
        directEmailAdditionalText.add('Summary Email - Member');
        directEmailAdditionalText.add('General');
        directEmailNOadditionalText = new List<String>();
        directEmailNOadditionalText.add('Grievance Investigation - Driver Statement');
        directEmailNOadditionalText.add('Grievance Investigation - Trip Information');
        directEmailNOadditionalText.add('Grievance Investigation - Accident Information');
        directEmailNOadditionalText.add('Remediation - 3PO');
        directEmailNOadditionalText.add('Summary Email - Facility');
   //     additionalTextDefaultEmail = new List<String>();
   //     additionalTextDefaultEmail.add();
   //     defaultEmailOnly = new List<String>();
   //     defaultEmail.add();
}


    /**
     * Krizia: select an Email Template and then make Additional Text and Email available or not
     */
    public void templateSelection() {
        System.debug('SendCaseEmailController::: templateSelection :: ' + string.valueOf(emailTemplateSelection));
        //Reset the additional email
        System.currentPageReference().getParameters().put('directEmail1', '');
        System.currentPageReference().getParameters().put('directEmail2', '');
        System.currentPageReference().getParameters().put('directEmail3', '');
        System.currentPageReference().getParameters().put('directEmail4', '');
        emailSubject = '';
        emailOutput = '';
        Integer emailType = getEmailOptionType(emailTemplateSelection);

        if (emailTemplateSelection == '--None--' || emailTemplateSelection == null) {
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'You did not select a Template. Please select an Email Template. ');
            ApexPages.addMessage(errorMessage);
            System.debug(errorMessage);
        }
        else if (emailType == 1) {
            disabledAdditional = false;
            disabledEmail = false;
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.WARNING, 'You selected an Email Template that accepts Additional Email Text and Email Address(es). Please add your comments in the text box below and Preview your entire Email before Sending. ');
            ApexPages.addMessage(errorMessage);
            System.debug(errorMessage);
        }
        else if (emailType == 2){
            additionalText = null;
            disabledAdditional = true;
            disabledEmail = false;
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.WARNING, 'You selected an Email Template that requires an Email Address. Please add the Email Address in the text box below and Preview your entire Email before Sending. ');
            ApexPages.addMessage(errorMessage);
            System.debug(errorMessage);
        }
        else if (emailType == 3) {
            directEmail1 = null;
            directEmail2 = null;
            directEmail3 = null;
            directEmail4 = null;
            additionalText = null;
            disabledAdditional = false;
            disabledEmail = true;
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.INFO, 'You selected an Email Template that accepts Additional Email Text. Please add your comments in the text box below and Preview your entire Email before Sending. ');
            ApexPages.addMessage(errorMessage);
            System.debug(errorMessage);
        }
        else {
            directEmail1 = null;
            directEmail2 = null;
            directEmail3 = null;
            directEmail4 = null;
            additionalText = null;
            disabledAdditional = true;
            disabledEmail = true;
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.INFO, 'You selected an Email Template that does not allow for Additional Email Text. Please send as is. ');
            ApexPages.addMessage(errorMessage);
            System.debug(errorMessage);
        }

        renderEmail();
    }


    /**
     * Krizia: show what the email will look like fully populated, do not send yet
     *
     */
    public void renderEmail() {
        gn.Additional_Email_Text__c = additionalText;
        System.debug('SendCaseEmailController::: renderEmail:: additionalText: ' + string.valueOf(additionalText) + ' TEMPLATE: ' + string.valueOf(emailTemplateSelection) + ' additionalEmails: ' + string.valueOf(directEmail1) + string.valueOf(directEmail2) + string.valueOf(directEmail3) + string.valueOf(directEmail4));
        update gn;


        //Falsify sending of email in order to see previewed body
        try {
            System.debug('renderEmail emailTemplateSelection: ' + string.valueOf(emailTemplateSelection));
            Id templateId = [SELECT Id FROM EmailTemplate WHERE Name = :emailTemplateSelection LIMIT 1].Id;


            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setTargetObjectId([SELECT Id FROM Contact WHERE Id = :gn.ContactId LIMIT 1].Id);
            email.setWhatId(gn.Id);
            email.setTemplateId(templateId);
            Savepoint sp = Database.setSavepoint();
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                    email
            });
            Database.rollback(sp);
            System.debug('SendCaseEmailController::: renderEmail:: ' + string.valueOf(email));
            emailOutput = email.getPlainTextBody();
            emailSubject = email.getSubject();
            System.debug('Email subject: ' + string.valueOf(emailSubject) + ' -- ' + string.valueOf(email.getSubject()));

        }
        catch (exception ex) {
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please make sure all input is correct, then try again. ');
            ApexPages.addMessage(errorMessage);
            System.debug(errorMessage);
            System.debug(ex);
        }
        disabledButton = true;
    } //public void renderEmail()


    /**
     * Krizia: Preview button will initiate email address tests and full email body preview as well as enabling send button
     */
    public void emailPreSend() {
        Boolean errorsBoolean = false;
        allRecipients = new List<String>();

        //Ensure the additional email is in good form
        if (directEmail1 != null) {
            if (directEmail1 != '' && isUserEmailValid(directEmail1) == false) {
                ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'Incorrect email address format. Please check that the first email address is correct and try again.');
                ApexPages.addMessage(errorMessage);
                System.debug(errorMessage);

                //Make sure they cannot send while the email address is incorrect
                disabledButton = true;
                errorsBoolean = true;
                //   return;
            }
            else {
                allRecipients.add(directEmail1);
            }
        }
        if (directEmail2 != null) {
            if (directEmail2 != '' && isUserEmailValid(directEmail2) == false) {
                ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'Incorrect email address format. Please check that the second email address is correct and try again.');
                ApexPages.addMessage(errorMessage);
                System.debug(errorMessage);

                //Make sure they cannot send while the email address is incorrect
                disabledButton = true;
                errorsBoolean = true;
                //   return;
            }
            else {
                allRecipients.add(directEmail2);
            }
        }
        if (directEmail3 != null) {
            if (directEmail3 != '' && isUserEmailValid(directEmail3) == false) {
                ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'Incorrect email address format. Please check that the third email address is correct and try again.');
                ApexPages.addMessage(errorMessage);
                System.debug(errorMessage);

                //Make sure they cannot send while the email address is incorrect
                disabledButton = true;
                errorsBoolean = true;
                //   return;
            }
            else {
                allRecipients.add(directEmail3);
            }
        }
        if (directEmail4 != null) {
            if (directEmail4 != '' && isUserEmailValid(directEmail4) == false) {
                ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'Incorrect email address format. Please check that the fourth email address is correct and try again.');
                ApexPages.addMessage(errorMessage);
                System.debug(errorMessage);

                //Make sure they cannot send while the email address is incorrect
                disabledButton = true;
                errorsBoolean = true;
                //   return;
            }
            else {
                allRecipients.add(directEmail4);
            }
        }
        if (errorsBoolean == true) {
            System.debug('There are errors in the additional email(s)');
            errorsBoolean = false;
            return;
        }

        //Display what the email will look like as well as Recipients and Subject
        renderEmail();

        disabledButton = false;

    } //public void emailPreSend


    /**
     * Krizia: figure out which CaseEmail method to call based on which Email Template needs to be sent, then send
     * after validations complete dealing with
     */
    public void onSend() {
        //Common for any template
        boolean success = false;
        String[] toRecipients = new List<String>();
        Id targetObjectId; // ** Must be a User, Contact, Lead, or Person ** (truly needs to be a Contact)
        Integer emailType = getEmailOptionType(emailTemplateSelection); //Check the Email Template type in order to assign the recipients properly


        //Recipients vary for Email Templates
        Contact c1;
        Contact c2;
        Contact c3;
        Contact c4;
        List<Contact> contactList = new List<Contact>();
        if (directEmail1 != null && directEmail1 != '') {
            c1 = new Contact(LastName = string.valueOf(directEmail1), Email = directEmail1);
            contactList.add(c1);
        }
        if (directEmail2 != null && directEmail2 != '') {
            c2 = new Contact(LastName = string.valueOf(directEmail2), Email = directEmail2);
            contactList.add(c2);
        }
        if (directEmail3 != null && directEmail3 != '') {
            c3 = new Contact(LastName = string.valueOf(directEmail3), Email = directEmail3);
            contactList.add(c3);
        }
        if (directEmail4 != null && directEmail4 != '') {
            c4 = new Contact(LastName = string.valueOf(directEmail4), Email = directEmail4);
            contactList.add(c4);
        }

        //New email addresses added
        System.debug('SendCaseEmailController::: contactList of recipients size: ' + string.valueOf(contactList.size()));
        if (contactList.size() > 0) {
            insert contactList;
            targetObjectId = contactList[0].Id;

            for (Contact c : contactList) {
                toRecipients.add(c.Email);
            }
        }
        else {
            targetObjectId = gn.ContactId;
            toRecipients.add(gn.ContactEmail);
        }

        //Attachments
        List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>{};
        List<ContentDocumentLink> chosenCDLs = new List<ContentDocumentLink>();
        if (attachments != null || attachments != '--None--') {
            System.debug('Attachments chosen, add them');
            //ContentDocument
            //add to chosenCDLs to then be queried in CaseEmail
            if (queriedContentDocuments != null) {
                if (queriedContentDocuments.size() > 0) {
                    for (ContentDocumentLink cdl : queriedContentDocuments) {
                        if (attachments.contains(cdl.ContentDocument.Title)) { // == attachments) {
                            System.debug(cdl.ContentDocument.Title);
                            chosenCDLs.add(cdl);
                        }
                    }
                    System.debug('chosenCDLs: ' + String.valueOf(chosenCDLs));
                }
            }

            //Actual Attachments
            //Add to emailAttachments
            if (queriedAttachments != null) {
                if (queriedAttachments.size() > 0) {
                    for (Attachment att : queriedAttachments) {
                        if (attachments.contains(att.Name)) { //== attachments) {
                            System.debug(att.Name);
                            Messaging.EmailFileAttachment attachME = new Messaging.EmailFileAttachment();

                            attachME.setBody(att.Body);
                            attachME.setFileName(att.Name);

                            emailAttachments.add(attachME);
                        }
                    }
                    System.debug('attachments: ' + string.valueOf(emailAttachments));
                }
            }
        }
        System.debug('emailAttachments: ' + string.valueOf(emailAttachments));

        //Email Templates using the Direct Email Address & additional input
        if (emailType == 1) {
            System.debug('RECIPIENTS: ' + toRecipients);
            if (emailAttachments.size() > 0 || chosenCDLs.size() > 0) {
                success = CaseEmail.sendEmailFromModalWithAttachments(gn, toRecipients, targetObjectId, emailTemplateSelection, emailAttachments, chosenCDLs);
            } else {
                success = CaseEmail.sendEmailFromModal(gn, toRecipients, targetObjectId, emailTemplateSelection);
            }
            delete contactList;
        }
        else if (emailType == 2) {//Email Templates using the Direct Email Address and no additional input
            System.debug('RECIPIENTS: ' + toRecipients);
            System.debug(contactList);
            if (emailAttachments.size() > 0 || chosenCDLs.size() > 0) {
                success = CaseEmail.sendEmailFromModalWithAttachments(gn, toRecipients, targetObjectId, emailTemplateSelection, emailAttachments, chosenCDLs);
            } else {
                success = CaseEmail.sendEmailFromModal(gn, toRecipients, targetObjectId, emailTemplateSelection);
            }
            delete contactList;
        }
//        else if (emailType == 3) { //Email Templates using the Submitting Contact (Owner) and Additional Text
//
//        }
//        else if (emailType == 4) { //Email Templates using the Submitting Contact (Owner) and NO Additional Text
//
//        }
        else {
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'You did not select an Email Template. Please select an Email Template, then try again. ');
            ApexPages.addMessage(errorMessage);
            System.debug(errorMessage);
        }
        System.debug('SUCCESS: ' + string.valueOf(success));


        //Display success
        if (success == true){
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Email sent. You may send another email or close the window.');
            ApexPages.addMessage(errorMessage);
            System.debug(errorMessage);
        }
        else {
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to send email. Please check that appropriate information is completed on the Grievance Note.');
            ApexPages.addMessage(errorMessage);
            System.debug(errorMessage);
            disabledButton = true;
        }

        //reset button so that they have to go through the entire process of selection and preview again
        disabledButton = true;
    }


    /**
     * Krizia: find out which option a list belongs to by passing in the Email Template Selection
     *
     * @return
     */
    public Integer getEmailOptionType(String ETS) {


        for (String s : directEmailAdditionalText) {
            if (s == ETS) { System.debug('EmailType: 1'); return (1); }
        }
        for (String s : directEmailNOadditionalText) {
            if (s == ETS) { System.debug('EmailType: 2'); return (2);  }
        }
//        for (String s : additionalTextDefaultEmail) { //Currently no templates fall into this category
//            if (s == ETS) { System.debug('EmailType: 3'); return (3);  }
//        }
//        for (String s : defaultEmailOnly) { //Currently no templates fall into this category
//            if (s == ETS) { System.debug('EmailType: 4'); return (4); }
//        }

        //If it wasn't in any of the lists
        return (10);
    }



    /**
    * Krizia: get email template picklist values in order to select from on the page
    *
    */
    public List<SelectOption> getEmailTemplates() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--None--'));

        Schema.DescribeFieldResult fieldResult = Case.Email_Template__c.getDescribe();
        List<Schema.PicklistEntry> pvalues = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry p : pvalues)
        {
            options.add(new SelectOption(p.getLabel(), p.getValue()));
        }
        System.debug('SendCaseEmailController::: getEmailTemplates:: ' + string.valueOf(options));
        return options;
    } //public List<SelectOption> getEmailTemplates()


    public static boolean isUserEmailValid(String userEmail) {
        Boolean flag = false;
        if(userEmail != null) {
            String  emailRegex      = '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
            Pattern emailPattern    = Pattern.compile(emailRegex);
            Matcher emailMatcher    = emailPattern.matcher(userEmail.trim());
            flag                    =  emailMatcher.matches();
        }
        return flag;
    } //public static boolean isUserEmailValid(String userEmail)


    /**
     * Krizia: need to get all attachments in order to attach one
     *
     * @return
     */
    public List<SelectOption> getAttachmentOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--None--'));


        System.debug(gn.Id);
        queriedAttachments = new List<Attachment>();
        queriedAttachments = [SELECT Id, Name, Body, ContentType, Description
            FROM Attachment
            WHERE ParentId =: gn.Id
            LIMIT 200];
        queriedContentDocuments = new List<ContentDocumentLink>();
        queriedContentDocuments = [SELECT ContentDocumentId, ContentDocument.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId =: gn.Id
            LIMIT 200];

        //Add all Internal Items ContentDocuments
        List<Internal_Item__c> iiList = new List<Internal_Item__c>();
        List<ContentDocumentLink> iiAttach = new List<ContentDocumentLink>();
        iiList = [SELECT Id FROM Internal_Item__c WHERE Case__c =: gn.Id LIMIT 200];

        List<Id> iiIds = new List<Id>();
        Set<Id> iiIdSet;
        if (iiList.size() > 0) {
            for (Internal_Item__c ii : iiList) {
                iiIds.add(ii.Id);
            }
            iiIdSet = new Set<Id>(iiIds);

            iiAttach = [SELECT ContentDocumentId, ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId IN :iiIdSet LIMIT 200];
        }




    //    contentDocs = new List<ContentDocument>();
        System.debug(queriedAttachments);
        System.debug(queriedContentDocuments);
        if (queriedAttachments.size() > 0) {
            for (Attachment att : queriedAttachments ){
                options.add(new SelectOption(att.Name,att.Name));
                System.debug(att.Name);
            }
        }
        if (queriedContentDocuments.size() > 0) {
            for (ContentDocumentLink cdl : queriedContentDocuments) {
                options.add(new SelectOption(cdl.ContentDocument.Title, cdl.ContentDocument.Title));
                System.debug(cdl.ContentDocument.Title);
            }
            for (ContentDocumentLink cdl2 : iiAttach) {
                options.add(new SelectOption(cdl2.ContentDocument.Title, cdl2.ContentDocument.Title));
                System.debug(cdl2.ContentDocument.Title);

                //Make sure to add Internal Items to be able to actually be sent with the Email
                queriedContentDocuments.add(cdl2);
            }
        }


        System.debug(options);
        return options;
    } //public List<SelectOption> getAttachmentOptions()
}