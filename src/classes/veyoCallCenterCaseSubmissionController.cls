public class veyoCallCenterCaseSubmissionController {

    // constants...
    private final String NONE = '--None--';
    private final String GRIEVANCE_NOTES_AND_FIRST_CALL_RESOLUTION = 'Grievance Notes and First Call Resolutions';
    private final String ONLY_GRIEVANCE_NOTES = 'Only Grievance Notes';
    private final String ONLY_FIRST_CALL_RESOLUTIONS = 'Only First Call Resolutions';
    private final String NEITHER = 'Neither';
    private final String FIRST_CALL_RESOLUTION = 'First Call Resolution';
    private final String GRIEVANCE_NOTE = 'Grievance Note';
    private final String PHONE = 'Phone';

    // member variables...
    public Case m_case { get; set; }
    public String caseType { get; set; }

    /**
     * Constructor
     */
    public veyoCallCenterCaseSubmissionController() {
        m_case = new Case();
        m_case.Date_of_Report__c = system.today();
        m_case.Contact_Type__c = PHONE;
    }

    /**
    *  returns collection to populate dropdown that drives
    *  wether the Call Center Agent can create
    *  Grievances or First Call Resolution, based on the
    *  Account (Health Plan) setting
    */
    public List<SelectOption> getCaseSubmissionTypes() {

        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', NONE));

        if(null != m_case.AccountId) {
            List<Account> accounts = [SELECT Call_Center_Can_Create__c
            FROM Account
            WHERE Id = :m_case.AccountId];
            if(accounts.size() > 0) {
                Account acct = accounts[0];
                if(acct.Call_Center_Can_Create__c == GRIEVANCE_NOTES_AND_FIRST_CALL_RESOLUTION) {
                    options.add(new SelectOption(FIRST_CALL_RESOLUTION, FIRST_CALL_RESOLUTION));
                    options.add(new SelectOption(GRIEVANCE_NOTE, GRIEVANCE_NOTE));

                } else if(acct.Call_Center_Can_Create__c == ONLY_GRIEVANCE_NOTES) {
                    options.add(new SelectOption(GRIEVANCE_NOTE, GRIEVANCE_NOTE));

                } else if(acct.Call_Center_Can_Create__c == ONLY_FIRST_CALL_RESOLUTIONS) {
                    options.add(new SelectOption(GRIEVANCE_NOTE, GRIEVANCE_NOTE));
                }
            }
        }
        return options;
    }

    /**
     *
     *
     * @return
     */
    public PageReference save() {

        if(null == m_case.AccountId) {
            ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.Error, 'You must select an Account');
            ApexPages.addMessage(errMsg);
            return null;
        }

        if(null == caseType || '' == caseType || NONE == caseType) {
            ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.Error, 'You must select an Incident Type');
            ApexPages.addMessage(errMsg);
            return null;
        }

        if(null == m_case.Member_Name__c) {
            ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.Error, 'You must enter the Member Name');
            ApexPages.addMessage(errMsg);
            return null;
        }

        if(GRIEVANCE_NOTE == caseType) {
            insert m_case;

        } else if (FIRST_CALL_RESOLUTION == caseType) {
            //TODO: coming soon...
        }

        PageReference pr = new PageReference(Apexpages.currentPage().getUrl());
        pr.setRedirect(true);
        return pr;

    }
}