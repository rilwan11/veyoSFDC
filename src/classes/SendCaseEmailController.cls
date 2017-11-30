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
    public String directEmail { get; set; }
    public boolean disabledEmail { get; set; }
    public boolean disabledButton { get; set; }
    public String emailSubject { get; set; }

    //Email Template lists for checking in Preview and Send methods
    public List<String> directEmailAdditionalText { get; set; }
    public List<String> directEmailNOadditionalText { get; set; }
    public List<String> additionalTextDefaultEmail { get; set; }
    public List<String> defaultEmailOnly { get; set; }



    public sendCaseEmailController(ApexPages.StandardController stdController) {
        //gn = (Case)stdControl.getRecord();
        Id recordId = ApexPages.CurrentPage().getParameters().get('Id');
        System.debug('SendCaseEmailController::: recordId: ' + string.valueOf(recordId));
        gn = [SELECT Id, CaseNumber, ContactId, Additional_Email_Text__c, Email_Template__c, AccountId
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

        System.currentPageReference().getParameters().put('directEmail', '');
        disabledEmail = false;

        disabledButton = true;

        //Make sure the Grievance has a Contact in order to set it as the targetObjectId when sending emails
        if (gn.ContactId == null) {
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please make sure there is a Contact on this Grievance. You cannot send emails without it. ');
            ApexPages.addMessage(errorMessage);
            System.debug(errorMessage);
        }


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
        additionalTextDefaultEmail = new List<String>();
   //     additionalTextDefaultEmail.add();
        defaultEmailOnly = new List<String>();
   //     defaultEmail.add();
}


    /**
     * Krizia: select an Email Template and then make Additional Text and Email available or not
     */
    public void templateSelection() {
        System.debug('SendCaseEmailController::: templateSelection :: ' + string.valueOf(emailTemplateSelection));
        //Reset the additional email
        System.currentPageReference().getParameters().put('directEmail', '');
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
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.WARNING, 'You selected an Email Template that accepts Additional Email Text. Please add your comments in the text box below and Preview your entire Email before Sending. ');
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
        else {
            directEmail = null;
            additionalText = null;
            disabledAdditional = true;
            disabledEmail = true;
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.INFO, 'You selected an Email Template that does not allow for Additional Email Text. Please send as is. ');
            ApexPages.addMessage(errorMessage);
            System.debug(errorMessage);
        }
    }


    /**
     * Krizia: show what the email will look like fully populated, do not send yet
     *
     */
    public void renderEmail() {
        gn.Additional_Email_Text__c = additionalText;
        System.debug('SendCaseEmailController::: renderEmail:: additionalText: ' + string.valueOf(additionalText) + ' TEMPLATE: ' + string.valueOf(emailTemplateSelection) + ' additionalEmail: ' + string.valueOf(directEmail));
        update gn;

        //Ensure the additional email is in good form
        if (directEmail != null) {
            if (directEmail != '' && isUserEmailValid(directEmail) == false) {
                ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'Incorrect email address format. Please check that the additional email is correct and try again.');
                ApexPages.addMessage(errorMessage);
                System.debug(errorMessage);

                //Make sure they cannot send while the email address is incorrect
                disabledButton = true;

                return;
            }
        }

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

            disabledButton = false;
        }
        catch (exception ex) {
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please make sure all input is correct and that there is a Contact on the Grievance, then try again. ');
            ApexPages.addMessage(errorMessage);
            System.debug(errorMessage);
            System.debug(ex);
            disabledButton = true;
        }
    }


    /**
     * Krizia: figure out which CaseEmail method to call based on which Email Template needs to be sent, then send
     * after validations complete dealing with
     */
    public void onSend() {
        //Common for any template
        boolean success = false;
        String[] toRecipients = new List<String>();
        Id targetObjectId; // ** Must be a User, Contact, Lead, or Person **
        Integer emailType = getEmailOptionType(emailTemplateSelection); //Check the Email Template type in order to assign the recipients properly


        //Recipients vary for Email Templates

        //Email Templates using the Direct Email Address & additional input
        if (emailType == 1) {
            Contact c = new Contact(LastName = string.valueOf(directEmail), Email = directEmail);
            insert c;
            toRecipients.add(c.Email);
            targetObjectId = c.Id;

            System.debug('RECIPIENTS: ' + toRecipients);
            success = CaseEmail.sendEmailFromModal(gn, toRecipients, targetObjectId, emailTemplateSelection);
            delete c;
        }
        else if (emailType == 2) {//Email Templates using the Direct Email Address and no additional input
            //Check if the driver email already exists
            List<Contact> cList = new List<Contact>();
            Contact c;
            cList = [SELECT Id, Email FROM Contact WHERE Email = :directEmail];

            //Use existing driver or make a new one
            if (cList.size() > 0) {
                c = cList.get(0);
            } else {
                c = new Contact(FirstName = 'requesting info from', LastName = 'Driver', Email = directEmail);
                insert c;
            }

            toRecipients.add(directEmail);
            System.debug('RECIPIENTS: ' + toRecipients);
            targetObjectId = c.Id;
            System.debug(c);
            success = CaseEmail.sendEmailFromModal(gn, toRecipients, targetObjectId, emailTemplateSelection);
        }
        else if (emailTemplateSelection == 'HCA/HCIC: Grievance Resolved - 1') {
            System.debug('OWNER: ' + string.valueOf(gn.OwnerId));
            Contact c = [SELECT Id, Email FROM Contact WHERE Id =: gn.ContactId LIMIT 1];
            toRecipients.add(c.Email);
            targetObjectId = c.Id;
            success = CaseEmail.sendEmailFromModal(gn, toRecipients, targetObjectId, emailTemplateSelection);
            //CaseEmail.sendResolved1(caseList);
        }
        else if (emailTemplateSelection == 'MCCVA: Grievance Resolved - 2') { //**** Need to know the small group this sends to
            Contact c = [SELECT Id, Email FROM Contact WHERE Id =: gn.ContactId LIMIT 1];
            toRecipients.add(c.Email);
            targetObjectId = c.Id;
            success = CaseEmail.sendEmailFromModal(gn, toRecipients, targetObjectId, emailTemplateSelection);
            //CaseEmail.sendResolved2(caseList);
        }
        else if (emailTemplateSelection == 'MCCFL: Grievance Resolved - 3') { //**** Need to know the same email it goes to each time
            Contact c = [SELECT Id, Email FROM Contact WHERE Id =: gn.ContactId LIMIT 1];
            toRecipients.add(c.Email);
            targetObjectId = c.Id;
            success = CaseEmail.sendEmailFromModal(gn, toRecipients, targetObjectId, emailTemplateSelection);
            //CaseEmail.sendResolved3(caseList);
        }
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
        for (String s : additionalTextDefaultEmail) {
            if (s == ETS) { System.debug('EmailType: 3'); return (3);  }
        }
        for (String s : defaultEmailOnly) {
            if (s == ETS) { System.debug('EmailType: 4'); return (4); }
        }

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
}