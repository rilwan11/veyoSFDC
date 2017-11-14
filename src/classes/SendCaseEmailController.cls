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



    public sendCaseEmailController(ApexPages.StandardController stdController) {
        //gn = (Case)stdControl.getRecord();
        Id recordId = ApexPages.CurrentPage().getParameters().get('Id');
        System.debug('SendCaseEmailController::: recordId: ' + string.valueOf(recordId));
        gn = [SELECT Id, CaseNumber, ContactId, Additional_Email_Text__c, Email_Template__c, AccountId
                FROM Case
                WHERE Id =: recordId
                LIMIT 1];
        a = [SELECT Id, Default_Account_Email_Address__c, Email_Template_1__c, Email_Template_2__c, Email_Template_3__c,
                Email_Template_4__c, Email_Template_5__c, Email_Recipient_1__c, Email_Recipient_2__c, Email_Recipient_3__c,
                Email_Recipient_4__c, Email_Recipient_5__c
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

        if (emailTemplateSelection == '--None--' || emailTemplateSelection == null) {
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'You did not select a Template. Please select an Email Template. ');
            ApexPages.addMessage(errorMessage);
            System.debug(errorMessage);
        }
        else if (emailTemplateSelection == 'KHB - Test Incoming Email') {
            disabledAdditional = false;
            disabledEmail = false;
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.WARNING, 'You selected an Email Template that accepts Additional Email Text. Please add your comments in the text box below and Preview your entire Email before Sending. ');
            ApexPages.addMessage(errorMessage);
            System.debug(errorMessage);
        }
        else if (emailTemplateSelection == 'Grievance Investigation - Driver Statement' || emailTemplateSelection == 'Grievance Investigation - Trip Log'){
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
            System.debug('KRIZIA HERE: ' + string.valueOf(emailSubject) + ' -- ' + string.valueOf(email.getSubject()));

            disabledButton = false;
        }
        catch (exception ex) {
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'You did not select an Email Template. Please select an Email Template, then try again. ');
            ApexPages.addMessage(errorMessage);
            System.debug(errorMessage);
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


        //Specific method for each Email Template due to the fact that recipients vary
        if (emailTemplateSelection == 'KHB - Test Incoming Email') {
            Contact c = [SELECT Id, Email FROM Contact WHERE Id =: gn.ContactId LIMIT 1];
            toRecipients.add(c.Email);
            targetObjectId = gn.ContactId;

            if (directEmail != '') {
                if (isUserEmailValid(directEmail) == true) {
                    toRecipients.add(directEmail);
                }
                else {
                    ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to send email. Please check that the additional email is correct and try again.');
                    ApexPages.addMessage(errorMessage);
                    System.debug(errorMessage);
                    disabledButton = true; 
                    return;
                }
            }
            System.debug('RECIPIENTS: ' + toRecipients);
            success = CaseEmail.sendEmailFromModal(gn, toRecipients, targetObjectId, emailTemplateSelection);
        }
        else if (emailTemplateSelection == 'MCCFL Only: Grievance Created - 1') { //***** Need Email this one always goes to
            Contact c = [SELECT Id, Email FROM Contact WHERE Id =: gn.ContactId LIMIT 1];
            toRecipients.add(c.Email);
            targetObjectId = c.Id;
            success = CaseEmail.sendEmailFromModal(gn, toRecipients, targetObjectId, emailTemplateSelection);
            //CaseEmail.sendMCCFLGNCreated1(caseList);
        }
        else if (emailTemplateSelection == 'Grievance Investigation - Driver Statement' || emailTemplateSelection == 'Grievance Investigation - Trip Log') { //ONLY SEND TO DRIVER
            if (directEmail != '') {
                if (isUserEmailValid(directEmail) == true) {
                    toRecipients.add(directEmail);
                } else {
                    ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to send email. Please check that the additional email is correct and try again.');
                    ApexPages.addMessage(errorMessage);
                    System.debug(errorMessage);
                    disabledButton = true;
                    return;
                }


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

                System.debug('RECIPIENTS: ' + toRecipients);
                targetObjectId = c.Id;
                System.debug(c);
                success = CaseEmail.sendEmailFromModal(gn, toRecipients, targetObjectId, emailTemplateSelection);
            }
            else {
                ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to send email. Please add an Email Address and try again.');
                ApexPages.addMessage(errorMessage);
                System.debug(errorMessage);
                disabledButton = true;
                return;
            }
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