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

    //Categories
    private final String COMPLAINT_CAT = 'Complaint';
    private final String LETTER_OF_INQUIRY_CAT = 'Letter of Inquiry';
    private final String QUALITY_OF_CARE_CONCERN_CAT = 'Quality of Care Concern';

    //Subcategories
    private final String AGENT_ISSUE_SUBCAT = 'Agent Issue';
    private final String DAMAGE_INJURY_SUBCAT = 'Damage/Injury';
    private final String DRIVER_ISSUE_SUBCAT = 'Driver Issue';
    private final String EARLY_ARRIVAL_SUBCAT = 'Early Arrival';
    private final String LATE_PICKUP_SUBCAT = 'Late Pickup';
    private final String MISSED_PICKUP_SUBCAT = 'Missed Pickup';
    private final String SAFETY_CONCERN_SUBCAT = 'Safety Concern';
    private final String SCHEDULING_ERROR_SUBCAT = 'Scheduling Error';
    private final String TECHNICAL_ISSUE_SUBCAT = 'Technical Issue';
    private final String VEHICLE_ISSUE_SUBCAT = 'Vehicle Issue';
    private final String MISSED_PICKUP_A_LEG_SUBCAT = 'Missed Pickup - A-Leg';
    private final String MISSED_PICKUP_B_LEG_SUBCAT = 'Missed Pickup - B-Leg';
    private final String LATE_PICKUP_A_LEG_SUBCAT = 'Late Pickup - A-Leg';
    private final String LATE_PICKUP_B_LEG_SUBCAT = 'Late Pickup - B-Leg';
    private final String OTHER_SUBCAT = 'Other';

    //Service Modes
    private final String AMBULATORY_SERVICE_MODE = 'Ambulatory';
    private final String WHEELCHAIR_SERVICE_MODE = 'Wheelchair';
    private final String BARIATRIC_WHEELCHAIR_SERVICE_MODE = 'Bariatric Wheelchair';
    private final String BLS_SERVICE_MODE = 'BLS';
    private final String ALS_SERVICE_MODE = 'ALS';
    private final String PUBLIC_TRANSPORTATION_SERVICE_MODE = 'Public Transportation';
    private final String MILEAGE_REIMBURSEMENT_SERVICE_MODE = 'Mileage Reimbursement';

    // member variables...
    public Case m_case { get; set; }
    public String caseType { get; set; }

    /**
     * Constructor
     */
    public veyoCallCenterCaseSubmissionController() {
        system.debug('veyoCallCenterCaseSubmissionController.constructor()...');
        m_case = new Case();
        m_case.Date_of_Report__c = system.today();
    //    m_case.Contact_Type__c = PHONE;
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
            List<Account> accounts = [SELECT Name, Call_Center_Can_Create__c
                                      FROM Account
                                      WHERE Id = :m_case.AccountId];


            if(accounts.size() > 0) {
                Account acct = accounts[0];
                System.debug('This account allows for: ' + string.valueOf(acct.Call_Center_Can_Create__c));

                system.debug('veyoCallCenterSubmissionController.getCaseSubmissionTypes() :: acct.Call_Center_Can_Create__c <'+acct.Call_Center_Can_Create__c+'>');

                if(GRIEVANCE_NOTES_AND_FIRST_CALL_RESOLUTION == acct.Call_Center_Can_Create__c) {
                    options.add(new SelectOption(FIRST_CALL_RESOLUTION, FIRST_CALL_RESOLUTION));
                    options.add(new SelectOption(GRIEVANCE_NOTE, GRIEVANCE_NOTE));

                } else if(ONLY_GRIEVANCE_NOTES == acct.Call_Center_Can_Create__c) {
                    options.add(new SelectOption(GRIEVANCE_NOTE, GRIEVANCE_NOTE));
                } else if(ONLY_FIRST_CALL_RESOLUTIONS == acct.Call_Center_Can_Create__c) {
                    options.add(new SelectOption(FIRST_CALL_RESOLUTION, FIRST_CALL_RESOLUTION));
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
    public String getAccountErrorMessage() {

        String errMsg;
        if(null != m_case.AccountId) {
            List<Account> accounts = [SELECT Name, Call_Center_Can_Create__c
                                      FROM Account
                                      WHERE Id = :m_case.AccountId];

            if(accounts.size() > 0) {
                Account acct = accounts[0];


                system.debug('veyoCallCenterSubmissionController.getCaseSubmissionTypes() :: acct.Call_Center_Can_Create__c <'+acct.Call_Center_Can_Create__c+'>');

                if(NEITHER == acct.Call_Center_Can_Create__c || NONE == acct.Call_Center_Can_Create__c || null == acct.Call_Center_Can_Create__c || '' == acct.Call_Center_Can_Create__c) {
                    errMsg = 'For '+acct.Name+', Veyo call center agents do not log Grievances into Salesforce.com. Please warm transfer this member to '+acct.Name+' member services.';
                }
                else if (ONLY_GRIEVANCE_NOTES == acct.Call_Center_Can_Create__c) {
                    errMsg = 'For ' + acct.Name + ', Veyo call center agents do not log First Call Resolutions into Salesforce. Please work with the member to resolve this issue. ';
                }
                else if (ONLY_FIRST_CALL_RESOLUTIONS == acct.Call_Center_Can_Create__c) {
                    errMsg = 'For ' + acct.Name + ', Veyo call center agents do not log Grievances into Salesforce. Please warm transfer this member to ' + Acct.Name + ' Member Services.';
                }
            }
        }

        return errMsg;
    }

    /**
     *
     *
     * @return
     */
    public Boolean getDisplayAccountErrorMessage() {

        if(null != m_case.AccountId) {
            List<Account> accounts = [SELECT Name, Call_Center_Can_Create__c
                                      FROM Account
                                      WHERE Id = :m_case.AccountId];

            if(accounts.size() > 0) {
                Account acct = accounts[0];

                system.debug('veyoCallCenterSubmissionController.getCaseSubmissionTypes() :: acct.Call_Center_Can_Create__c <'+acct.Call_Center_Can_Create__c+'>');

                if(NEITHER == acct.Call_Center_Can_Create__c || NONE == acct.Call_Center_Can_Create__c || null == acct.Call_Center_Can_Create__c || '' == acct.Call_Center_Can_Create__c) {
                    return true;
                }
                else if (ONLY_FIRST_CALL_RESOLUTIONS == acct.Call_Center_Can_Create__c || ONLY_GRIEVANCE_NOTES == acct.Call_Center_Can_Create__c) {
                    //Adding to keep Call Center Agents from completing a call on an Account that does not support FCRs or GNs
                    return true;
                }
            }
        }

        return false;
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

        //Set source based on who is submitting the Member Assistance
        List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
        String profileName = PROFILE[0].Name;
        if (profileName == 'Call Center Escalation Agents') {
            System.debug('Submitted by Call Center Escalation Agent');
            m_case.Source__c = 'Call Center';
            m_case.Contact_Type__c = PHONE;
        } else if (profileName == 'QA Coordinators' || profileName == 'QA Management') {
            System.debug('Submitted by QA');
            m_case.Source__c = 'QA Team';
        } else if (profileName == 'Quality Assurance Community Profile') {
            System.debug('Submitted by Client');
            m_case.Source__c = 'Client Community';
        }

        //Set Submitting Contact behind the scenes as the Owner of the Member Assistance
        List<Contact> possibleDups = [SELECT Id, Name, Email FROM Contact WHERE Email =: userinfo.getUserEmail()];
        Contact c = new Contact();
        if (possibleDups.size() > 0) {
            System.debug('This User already exists as a Contact: ' + string.valueOf(possibleDups[0]));
            m_case.ContactId = possibleDups[0].Id;
            System.debug(m_case.ContactId);
        } else {
            c.LastName = userinfo.getLastName();
            c.Email = userinfo.getUserEmail();
            System.debug('This User is a new Contact: ' + string.valueOf(c));
            insert c;
        }

        RecordType CaseGN = [SELECT Id, Name FROM RecordType WHERE SobjectType = 'Case' AND Name = 'Grievance Note' LIMIT 1];
        RecordType CaseFCR = [SELECT Id, Name FROM RecordType WHERE SobjectType = 'Case' AND Name = 'First Call Resolution' LIMIT 1];

        if(GRIEVANCE_NOTE == caseType) {
            m_case.RecordTypeId = CaseGN.Id;
            insert m_case;
            System.debug(m_case);
        } else if (FIRST_CALL_RESOLUTION == caseType) {
            m_case.RecordTypeId = CaseFCR.Id;
            m_case.Contact_Type__c = PHONE;
            insert m_case;
            System.debug(m_case);
        }

        PageReference pr = new PageReference(Apexpages.currentPage().getUrl());
        pr.setRedirect(true);
        return pr;

    }

    /**
     *
     *
     * @return
     */
    public List<SelectOption> getCategoryOptions() {

        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--None--'));

        if(null == m_case.AccountId) {
            return options;
        }

        // get Account data from DB...
        List<Account> accounts = [SELECT Id, Complaint_Category__c, Quality_of_Care_Concern_Category__c, Letter_of_Inquiry_Category__c
                                  FROM Account
                                  WHERE Id = :m_case.AccountId];

        if(accounts.size() > 0) {

            Account acct = accounts[0];

            //Add to Categories picklist
            if (acct.Complaint_Category__c == true) {
                options.add(new SelectOption(COMPLAINT_CAT, COMPLAINT_CAT));
            }
            if (acct.Quality_of_Care_Concern_Category__c == true) {
                options.add(new SelectOption(QUALITY_OF_CARE_CONCERN_CAT, QUALITY_OF_CARE_CONCERN_CAT));
            }
            if (acct.Letter_of_Inquiry_Category__c == true) {
                options.add(new SelectOption(LETTER_OF_INQUIRY_CAT, LETTER_OF_INQUIRY_CAT));
            }
        }

        return options;
    }
    /**
     *
     *
     * @return
     */
    public List<SelectOption> getSubcategoryOptions() {

        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--None--'));

        if(null == m_case.AccountId) {
            return options;
        }

        // get Account data from DB...
        List<Account> accounts = [SELECT Id, Agent_Issue_Subcategory__c, Damage_Injury_Subcategory__c, Driver_Issue_Subcategory__c,
                                    Early_Arrival_Subcategory__c, Late_Pickup_Subcategory__c, Missed_Pickup_Subcategory__c, Safety_Concern_Subcategory__c,
                                    Scheduling_Error_Subcategory__c, Technical_Issue_Subcategory__c, Vehicle_Issue_Subcategory__c, Missed_Pickup_A_Leg_Subcategory__c,
                                    Missed_Pickup_B_Leg_Subcategory__c, Late_Pickup_A_Leg_Subcategory__c, Late_Pickup_B_Leg_Subcategory__c, Other_Subcategory__c
                                  FROM Account
                                  WHERE Id = :m_case.AccountId];
        if(accounts.size() > 0) {

            Account a = accounts[0];

            //Add to Subcategories picklist
            if (a.Agent_Issue_Subcategory__c == true) {
                options.add(new SelectOption(AGENT_ISSUE_SUBCAT, AGENT_ISSUE_SUBCAT));
            }
            if (a.Damage_Injury_Subcategory__c == true) {
                options.add(new SelectOption(DAMAGE_INJURY_SUBCAT, DAMAGE_INJURY_SUBCAT));
            }
            if (a.Driver_Issue_Subcategory__c == true) {
                options.add(new SelectOption(DRIVER_ISSUE_SUBCAT, DRIVER_ISSUE_SUBCAT));
            }
            if (a.Early_Arrival_Subcategory__c == true) {
                options.add(new SelectOption(EARLY_ARRIVAL_SUBCAT, EARLY_ARRIVAL_SUBCAT));
            }
            if (a.Late_Pickup_Subcategory__c == true) {
                options.add(new SelectOption(LATE_PICKUP_SUBCAT, LATE_PICKUP_SUBCAT));
            }
            if (a.Missed_Pickup_Subcategory__c == true) {
                options.add(new SelectOption(MISSED_PICKUP_SUBCAT, MISSED_PICKUP_SUBCAT));
            }
            if (a.Safety_Concern_Subcategory__c == true) {
                options.add(new SelectOption(SAFETY_CONCERN_SUBCAT, SAFETY_CONCERN_SUBCAT));
            }
            if (a.Scheduling_Error_Subcategory__c == true) {
                options.add(new SelectOption(SCHEDULING_ERROR_SUBCAT, SCHEDULING_ERROR_SUBCAT));
            }
            if (a.Technical_Issue_Subcategory__c == true) {
                options.add(new SelectOption(TECHNICAL_ISSUE_SUBCAT, TECHNICAL_ISSUE_SUBCAT));
            }
            if (a.Vehicle_Issue_Subcategory__c == true) {
                options.add(new SelectOption(VEHICLE_ISSUE_SUBCAT, VEHICLE_ISSUE_SUBCAT));
            }
            if (a.Missed_Pickup_A_Leg_Subcategory__c == true) {
                options.add(new SelectOption(MISSED_PICKUP_A_LEG_SUBCAT, MISSED_PICKUP_A_LEG_SUBCAT));
            }
            if (a.Missed_Pickup_B_Leg_Subcategory__c == true) {
                options.add(new SelectOption(MISSED_PICKUP_B_LEG_SUBCAT, MISSED_PICKUP_B_LEG_SUBCAT));
            }
            if (a.Late_Pickup_A_Leg_Subcategory__c == true) {
                options.add(new SelectOption(LATE_PICKUP_A_LEG_SUBCAT, LATE_PICKUP_A_LEG_SUBCAT));
            }
            if (a.Late_Pickup_B_Leg_Subcategory__c == true) {
                options.add(new SelectOption(LATE_PICKUP_B_LEG_SUBCAT, LATE_PICKUP_B_LEG_SUBCAT));
            }
            if (a.Other_Subcategory__c == true) {
                options.add(new SelectOption(OTHER_SUBCAT, OTHER_SUBCAT));
            }
        }

        return options;
    }

    /**
     *
     *
     * @return
     */
    public List<SelectOption> getServiceModeOptions() {

        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--None--'));

        if(null == m_case.AccountId) {
            return options;
        }

        // get Account data from DB...
        List<Account> accounts = [SELECT Id, Ambulatory_Service_Mode__c, Wheelchair_Service_Mode__c, Bariatric_Wheelchair_Service_Mode__c,
                                    BLS_Service_Mode__c, ALS_Service_Mode__c, Public_Transportation_Service_Mode__c, Mileage_Reimbursement_Service_Mode__c
                                  FROM Account
                                  WHERE Id = :m_case.AccountId];

        if(accounts.size() > 0) {

            Account a = accounts[0];

            //Add to Service modes picklist
            if (a.Ambulatory_Service_Mode__c == true) {
                options.add(new SelectOption(AMBULATORY_SERVICE_MODE, AMBULATORY_SERVICE_MODE));
            }
            if (a.Wheelchair_Service_Mode__c == true) {
                options.add(new SelectOption(WHEELCHAIR_SERVICE_MODE, WHEELCHAIR_SERVICE_MODE));
            }
            if (a.Bariatric_Wheelchair_Service_Mode__c == true) {
                options.add(new SelectOption(BARIATRIC_WHEELCHAIR_SERVICE_MODE, BARIATRIC_WHEELCHAIR_SERVICE_MODE));
            }
            if (a.BLS_Service_Mode__c == true) {
                options.add(new SelectOption(BLS_SERVICE_MODE, BLS_SERVICE_MODE));
            }
            if (a.ALS_Service_Mode__c == true) {
                options.add(new SelectOption(ALS_SERVICE_MODE, ALS_SERVICE_MODE));
            }
            if (a.Public_Transportation_Service_Mode__c == true) {
                options.add(new SelectOption(PUBLIC_TRANSPORTATION_SERVICE_MODE, PUBLIC_TRANSPORTATION_SERVICE_MODE));
            }
            if (a.Mileage_Reimbursement_Service_Mode__c == true) {
                options.add(new SelectOption(MILEAGE_REIMBURSEMENT_SERVICE_MODE, MILEAGE_REIMBURSEMENT_SERVICE_MODE));
            }
        }

        return options;
    }

    /**
     *
     *
     * @return
     */
    public List<SelectOption> getProviders() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--None--'));

        if(null == m_case.AccountId) {
            return options;
        }

        List<Account> clientAccts = [SELECT Id, Service_State__c
                                     FROM Account
                                     WHERE Id = :m_case.AccountId];

        List<RecordType> recTypes = [SELECT Id, DeveloperName, SobjectType
                                     FROM RecordType
                                     WHERE SobjectType = 'Account'
                                       AND DeveloperName = 'Transportation_Provider'];


        if(clientAccts.size() > 0 && recTypes.size() > 0) {
            RecordType rtProvider = recTypes[0];
            Account clntAcct = clientAccts[0];

            List<Account> providerAccts = [SELECT Id, Name
                                           FROM Account
                                           WHERE Service_State__c = :clntAcct.Service_State__c
                                             AND RecordTypeId = :rtProvider.Id
                                           ORDER BY Name];

            for(Account providerAcct : providerAccts) {
                options.add(new SelectOption(providerAcct.Id, providerAcct.Name));
            }
        }

        return options;
    }
}