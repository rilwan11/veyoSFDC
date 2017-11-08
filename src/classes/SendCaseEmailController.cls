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

        //Make sure the Grievance has a Contact in order to set it as the targetObjectId when sending emails
        if (gn.ContactId == null) {
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please make sure there is a Contact on this Grievance. You cannot send emails without it. ');
            ApexPages.addMessage(errorMessage);
            System.debug(errorMessage);
        }
    }


    /**
     * Krizia: select an Email Template and then make Additional Text available or not
     */
    public void templateSelection() {
        System.debug('SendCaseEmailController::: templateSelection :: ' + string.valueOf(emailTemplateSelection));

        if (emailTemplateSelection == 'KHB - Test Incoming Email') {
            disabledAdditional = false;
            disabledEmail = false;
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.WARNING, 'You selected an Email Template that accepts Additional Email Text. Please add your comments in the text box below and Preview your entire Email before Sending. ');
            ApexPages.addMessage(errorMessage);
            System.debug(errorMessage);
        }
        else if (emailTemplateSelection == 'Grievance Investigation - Driver Statement' || emailTemplateSelection == 'Grievance Investigation - Trip Log'){
            disabledAdditional = true;
            disabledEmail = false;
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.WARNING, 'You selected an Email Template that requires an Email Address. Please add the Email Address in the text box below and Preview your entire Email before Sending. ');
            ApexPages.addMessage(errorMessage);
            System.debug(errorMessage);
        }
        else {
            System.currentPageReference().getParameters().put('additionalText','');
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
        System.debug('SendCaseEmailController::: renderEmail:: additionalText ' + string.valueOf(additionalText));
        update gn;

        //Ensure the additional email is
        if (directEmail != '' && isUserEmailValid(directEmail) == false) {
                ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to send email. Please check that the additional email is correct and try again.');
                ApexPages.addMessage(errorMessage);
                System.debug(errorMessage);
                return;
        }

        //Falsify sending of email in order to see previewed body
        if (emailTemplateSelection != null) {
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
        }
        else {
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'You did not select an Email Template. Please select an Email Template, then try again. ');
            ApexPages.addMessage(errorMessage);
            System.debug(errorMessage);
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

            if (directEmail != '') {
                if (isUserEmailValid(directEmail) == true) {
                    toRecipients.add(directEmail);
                }
                else {
                    ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to send email. Please check that the additional email is correct and try again.');
                    ApexPages.addMessage(errorMessage);
                    System.debug(errorMessage);
                    return;
                }
            }
            System.debug('RECIPIENTS: ' + toRecipients);
            targetObjectId = gn.ContactId;
            success = CaseEmail.sendEmailFromModal(gn, toRecipients, targetObjectId, emailTemplateSelection);
        }
        else if (emailTemplateSelection == 'MCCFL Only: Grievance Created - 1') { //***** Need Email this one always goes to
            toRecipients.add('krizia.buck@revcult.com');
            targetObjectId = [SELECT Id FROM Contact WHERE Id =: gn.ContactId LIMIT 1].Id;
         //   targetObjectId =
            success = CaseEmail.sendEmailFromModal(gn, toRecipients, targetObjectId, emailTemplateSelection);
            //CaseEmail.sendMCCFLGNCreated1(caseList);
        }
        else if (emailTemplateSelection == 'Grievance Investigation - Driver Statement') { //**** Need the Driver's email
            if (isUserEmailValid(directEmail) == true) {
                toRecipients.add(directEmail);
            }
            else {
                ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to send email. Please check that the additional email is correct and try again.');
                ApexPages.addMessage(errorMessage);
                System.debug(errorMessage);
                return;
            }

            System.debug('RECIPIENTS: ' + toRecipients);
            Contact c = [SELECT Id, Email FROM Contact WHERE Id =: gn.ContactId LIMIT 1];
            targetObjectId = c.Id;
            success = CaseEmail.sendEmailFromModal(gn, toRecipients, targetObjectId, emailTemplateSelection);
            //CaseEmail.sendDriverStatement(caseList);
        }
        else if (emailTemplateSelection == 'Grievance Investigation - Trip Log') { //**** Need to know the email of who the Trip Log is requested from
            if (isUserEmailValid(directEmail) == true) {
                toRecipients.add(directEmail);
            }
            else {
                ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to send email. Please check that the additional email is correct and try again.');
                ApexPages.addMessage(errorMessage);
                System.debug(errorMessage);
                return;
            }

            Contact c = [SELECT Id, Email FROM Contact WHERE Id =: gn.ContactId LIMIT 1];
            targetObjectId = c.Id;
            success = CaseEmail.sendEmailFromModal(gn, toRecipients, targetObjectId, emailTemplateSelection);

            //CaseEmail.sendTripLog(caseList);
        }
        else if (emailTemplateSelection == 'HCA/HCIC: Grievance Resolved - 1') {
            System.debug('OWNER: ' + string.valueOf(gn.OwnerId));
            User u = [SELECT Id, Email FROM User WHERE Id =: gn.OwnerId];
            toRecipients.add(u.Email);
            targetObjectId = u.Id;
            success = CaseEmail.sendEmailFromModal(gn, toRecipients, targetObjectId, emailTemplateSelection);
            //CaseEmail.sendResolved1(caseList);
        }
        else if (emailTemplateSelection == 'MCCVA: Grievance Resolved - 2') { //**** Need to know the small group this sends to
            toRecipients.add('k@ikrizia.com');
            toRecipients.add('krizia.buck@revcult.com');
          // targetObjectId =
            success = CaseEmail.sendEmailFromModal(gn, toRecipients, targetObjectId, emailTemplateSelection);
            //CaseEmail.sendResolved2(caseList);
        }
        else if (emailTemplateSelection == 'MCCFL: Grievance Resolved - 3') { //**** Need to know the same email it goes to each time
            toRecipients.add('kriziabuck@gmail.com');
         // targetObjectId =
            success = CaseEmail.sendEmailFromModal(gn, toRecipients, targetObjectId, emailTemplateSelection);
            //CaseEmail.sendResolved3(caseList);
        }
        else {
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'You did not select an Email Template. Please select an Email Template, then try again. ');
            ApexPages.addMessage(errorMessage);
            System.debug(errorMessage);
        }
        System.debug('SUCCESS: ' + string.valueOf(success));


        //Display success and close modal
        if (success == true){
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.INFO, 'Email sent. You may send another email or close the window.');
            ApexPages.addMessage(errorMessage);
            System.debug(errorMessage);
        }
        else {
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to send email. Please check that appropriate information is completed on the Grievance Note.');
            ApexPages.addMessage(errorMessage);
            System.debug(errorMessage);
        }
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