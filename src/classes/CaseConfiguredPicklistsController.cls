/**
 * Created by krizia on 11/3/17.
 */

public with sharing class CaseConfiguredPicklistsController {
    public String caseCategory { get; set; }
    public String caseSubcategory { get; set; }
    public String caseServiceMode { get; set; }
    public String caseTransportationProvider { get; set; }
    public String caseProviderContact { get; set; }
    public Case gn { get; set; }
    public Account a { get; set; }
    private ApexPages.StandardController sc;

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

    //Service Modes
    private final String AMBULATORY_SERVICE_MODE = 'Ambulatory';
    private final String WHEELCHAIR_SERVICE_MODE = 'Wheelchair';
    private final String BARIATRIC_WHEELCHAIR_SERVICE_MODE = 'Bariatric Wheelchair';
    private final String BLS_SERVICE_MODE = 'BLS';
    private final String ALS_SERVICE_MODE = 'ALS';
    private final String PUBLIC_TRANSPORTATION_SERVICE_MODE = 'Public Transportation';
    private final String MILEAGE_REIMBURSEMENT_SERVICE_MODE = 'Mileage Reimbursement';


    /**
     * Krizia: constructor, initialize as the current Grievance
     *
     * @param stdController
     */
    public CaseConfiguredPicklistsController(ApexPages.StandardController stdController) {
        sc = stdController;
        Id recordId;
        List<Case> grievances = new List<Case>();
        gn = new Case();
        a = new Account();

        if (ApexPages.CurrentPage().getParameters().get('Id') != null) {
            recordId = ApexPages.CurrentPage().getParameters().get('Id');

        //String recordNumber = ApexPages.CurrentPage().getParameters().get('CaseNumber');
        System.debug('CaseConfiguredPicklistsController::: recordId: ' + string.valueOf(recordId));

        grievances = [SELECT Id, CaseNumber, AccountId, ContactId, Status, Provider_Contact__c, Category__c, Subcategory__c, Service_Mode__c,
                CreatedById, Member_Name__c, Date_of_Report__c, Member_ID__c, Due_Date__c, Member_Phone_Number__c,
                Complainant_Name__c, CreatedDate, Created__c, Type, Contact_Type__c, Progress_Date__c, User_Account__c,
                Resolved__c, Follow_Up_Requested__c, Open_Email_Response__c, Follow_Up_Completed__c, Follow_Up_Comments__c,
                Description, Priority, Provider_Name__c, Trip_Date__c, Agent_Name__c, Driver_Name__c, Vehicle_Number__c,
                Employee_Name__c, Date_of_Investigation__c, Investigator_Comments__c, Substantiated__c, Action_Taken__c,
                Complaint_Origin__c, Trip_Number__c, Origin_Name__c, If_Null_Why__c, Additional_Origin_Name__c, Grievance_Detail__c,
                Trip_Fraud__c, Call_Recordings__c, Fraud_Trip_Number__c, Field_Notes__c, Fraud_Trip_Number_Additional__c,
                Date_When_Reached_Out_to_Provider__c, Blank_Field_1__c, Blank_Field_2__c, Blank_Field_3__c, Blank_Field_4__c,
                OwnerId, LastModifiedById, Age_in_Days__c, ContactEmail, Case_Age_in_Business_Hours__c, Origin, Time_With_Support__c,
                ContactPhone, Time_With_Customer__c, Subject, Follow_Up_Period__c, Follow_Up_Age_In_Days__c, Reason,
                Follow_Up_Age__c, Follow_Up_Time_With_Support__c, Follow_Up_Time_With_Customer__c,
                Selected_For_Audit__c, Auditor__c, Audit_Date__c, Feedback__c, Investigation_Date__c, Service_Detail__c, Status_audit__c,
                Internal_Feed__c, Notes_Attachments_Recordings__c, Provider_Name_audit__c, Subcategory_audit__c, Trip_Date_audit__c,
                Trip_Number_audit__c, Trip_Details__c, Data_Entry_Score__c, All_Issues_Investigated__c, Clear_Timeline_of_Events__c,
                Avoids_Jargon_or_Internal_Communication__c, Uses_Spell_Check__c, Proper_Use_of_Grammar__c, Account_Protocol__c,
                Investigation_Score__c, Substantiation_Accurate__c, Actions_Taken__c
                FROM Case
                WHERE Id =: recordId //CaseNumber =: recordNumber
                LIMIT 1];
        }

        if (grievances.size() > 0) {
            gn = grievances[0];
        }
        else {
            gn = new Case();
        }

        List<Account> accList = new List<Account>();
        accList = [SELECT Id, Service_State__c, RecordTypeId, Record_Type_Name__c, Complaint_Category__c, Quality_of_Care_Concern_Category__c, Letter_of_Inquiry_Category__c,
                        Agent_Issue_Subcategory__c, Driver_Issue_Subcategory__c, Early_Arrival_Subcategory__c, Late_Pickup_Subcategory__c, Damage_Injury_Subcategory__c, Missed_Pickup_Subcategory__c,
                        Safety_Concern_Subcategory__c, Scheduling_Error_Subcategory__c, Technical_Issue_Subcategory__c, Vehicle_Issue_Subcategory__c, Missed_Pickup_A_Leg_Subcategory__c, Missed_Pickup_B_Leg_Subcategory__c,
                        Late_Pickup_A_Leg_Subcategory__c, Late_Pickup_B_Leg_Subcategory__c,
                        Wheelchair_Service_Mode__c, Bariatric_Wheelchair_Service_Mode__c, BLS_Service_Mode__c, ALS_Service_Mode__c, Ambulatory_Service_Mode__c, Public_Transportation_Service_Mode__c, Mileage_Reimbursement_Service_Mode__c
                FROM Account
                WHERE Id = :gn.AccountId
                LIMIT 1
        ];
        if (accList.size() > 0) {
            a = accList[0];
        }
        else {
            a = new Account();
        }

        System.debug('CaseConfiguredPicklistsController::: constructor:: gn: ' + string.valueOf(gn));
        System.debug('STATUS here: ' + string.valueOf(gn.Status));
    } //public CaseConfiguredPicklistsController(ApexPages.StandardController stdController)


    /**
     * Krizia: make specific Categories available in picklist based upon Account Configuration
     */
    public List<SelectOption> getCategoryOptions() {
        System.debug('CaseConfiguredPicklistsController::: getCategoryOptions:: ');
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--None--'));

        //Add to Categories picklist
        if (a.Complaint_Category__c == true) {
            options.add(new SelectOption(COMPLAINT_CAT, COMPLAINT_CAT));
        }
        if (a.Quality_of_Care_Concern_Category__c == true) {
            options.add(new SelectOption(QUALITY_OF_CARE_CONCERN_CAT, QUALITY_OF_CARE_CONCERN_CAT));
        }
        if (a.Letter_of_Inquiry_Category__c == true) {
            options.add(new SelectOption(LETTER_OF_INQUIRY_CAT, LETTER_OF_INQUIRY_CAT));
        }

        //Initial value to put into Category
        if (gn.Category__c != null) {
            System.debug('CaseConfiguredPicklistsController::: getCategoryOptions:: set Category to previous value - ' + string.valueOf(gn.Category__c));
            String cat = gn.Category__c;
            caseCategory = cat;
        }

        return options;
    } //public List<SelectOption> categoryOptions()

    /**
     * Krizia: make specific Subcategories available in picklist based upon Account Configuration
     */
    public List<SelectOption> getSubcategoryOptions() {
        System.debug('CaseConfiguredPicklistsController::: getSubcategoryOptions:: ');
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--None--'));

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

        //Initial value to put into Subcategory
        if (gn.Subcategory__c != null) {
            System.debug('CaseConfiguredPicklistsController::: getSubcategoryOptions:: set Subcategory to previous value - ' + string.valueOf(gn.Subcategory__c));
            String subcat = gn.Subcategory__c;
            caseSubcategory = subcat;
        }

        return options;
    } //public List<SelectOption> subcategoryOptions()


    /**
     * Krizia: make specific Service Modes available in picklist based upon Account Configuration
     */
    public List<SelectOption> getServiceModeOptions() {
        System.debug('CaseConfiguredPicklistsController::: getServiceModeOptions:: ');
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--None--'));

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

        //Initial value to put into Service Mode
        if (gn.Service_Mode__c != null) {
            System.debug('CaseConfiguredPicklistsController::: getServiceModeOptions:: set Service Mode to previous value - ' + string.valueOf(gn.Service_Mode__c));
            String serv = gn.Service_Mode__c;
            caseServiceMode = serv;
        }

        return options;
    } //public List<SelectOption> serviceModeOptions()


    /**
     * Krizia: make specific Transportation Providers available in picklist based upon Account Service State
    */
    public List<SelectOption> getTransportationProviderOptions() {
        System.debug('CaseConfiguredPicklistsController::: getTransportationProviderOptions:: ');
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--None--'));

        if (a.Service_State__c != null) {
            //Add to Provider Contact picklist
            List<Account> transportationProviders = new List<Account>();
            transportationProviders = [
                    SELECT Id, Name, Service_State__c
                    FROM Account
                    WHERE Service_State__c =: a.Service_State__c AND Record_Type_Name__c = 'Transportation Provider'
            ];


            if (transportationProviders.size() > 0) {
                for (Account a : transportationProviders) {
                    String aName = a.Name;
                    options.add(new SelectOption(aName, aName));
                }
            }
        }
        //Initial value to put into Provider Name (Transportation Provider)
        if (gn.Provider_Name__c != null) {
            System.debug('CaseConfiguredPicklistsController::: getTransportationProviderOptions:: set TransportationProvider to previous value - ' + string.valueOf(gn.Provider_Name__c));
            String tp = gn.Provider_Name__c;
            caseTransportationProvider = tp;
        }

        return options;
    } //public List<SelectOption> getTransportationProviderOptions()


    /**
      * Krizia: make specific Transportation Provider Contacts available in picklist based upon Account Service State and Transportation Provider Account
     */
    public List<SelectOption> getProviderContactOptions() {
        System.debug('CaseConfiguredPicklistsController::: getProviderContactOptions:: ' + string.valueOf(caseTransportationProvider));
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--None--'));

        //Add to Provider Contact picklist
        if (a.Service_State__c != null && (caseTransportationProvider != null)) {
            List<Account> transportationProvider = new List<Account>();
            transportationProvider = [
                    SELECT Id, Name, Service_State__c
                    FROM Account
                    WHERE Name =: caseTransportationProvider
                    LIMIT 1
            ];
            if (transportationProvider.size() > 0) {
                List<Contact> contacts = new List<Contact>();
                contacts = [
                        SELECT Id, Name
                        FROM Contact
                        WHERE AccountId = :transportationProvider[0].Id
                ];

                if (contacts.size() > 0) {
                    for (Contact c : contacts) {
                        String cName = c.Name;
                        options.add(new SelectOption(cName, cName));
                    }
                }
            }
        }


        //Initial value to put into Provider Contact
        if (gn.Provider_Contact__c != null) {
            System.debug('CaseConfiguredPicklistsController::: getProviderContactOptions:: set Provider Contact to previous value - ' + string.valueOf(gn.Provider_Contact__c));
            String pc = gn.Provider_Contact__c;
            caseProviderContact = pc;
        }

        return options;
    } //public List<SelectOption> getProviderContactOptions()


    /**
     * Krizia: button - update the Case with the selected Category, Subcategory, and Service Mode as well as normal fields
     */
    public pageReference updatePicklists() {
        System.debug('CaseConfiguredPicklistsController::: updatePicklists:: Status: ' + string.valueOf(gn.Status));

        //Check to be sure that Follow Up Comments entered when trying to change Status to Follow Up Requested
        if (gn.Status == 'Follow Up Requested') {
            if (gn.Follow_Up_Comments__c == '' || gn.Follow_Up_Comments__c == null) {
                System.debug('CaseConfiguredPicklistsController::: updatePicklists:: Follow Up Requested and no Follow Up Comments');
                ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to save, please enter Follow Up Comments to move into Follow Up Requested.');
                ApexPages.addMessage(errorMessage);
                System.debug(errorMessage);
                return null;
            }
            System.debug('CaseConfiguredPicklistsController::: updatePicklists:: Follow Up Requested with Follow Up Comments');
        }


        System.debug('STATUS here 2: ' + string.valueOf(gn.Status));
        //Update the three values available in this picklist page
        gn.Category__c = caseCategory;
        gn.Subcategory__c = caseSubcategory;
        gn.Service_Mode__c = caseServiceMode;
        gn.Provider_Name__c = caseTransportationProvider;
        gn.Provider_Contact__c = caseProviderContact;

        System.debug('CaseConfiguredPicklistsController::: updatePicklists:: ' + string.valueOf(gn));

        if (gn.Id == null) {
            insert gn;
            System.debug('CaseConfiguredPicklistsController::: updatePicklists:: inserting gn');
        }
        else {
            update gn;
            System.debug('CaseConfiguredPicklistsController::: updatePicklists:: updating gn');
        }
        System.debug('STATUS here 3: ' + string.valueOf(gn.Status));

        //TEMP: PageReference pr = new PageReference(ApexPages.currentPage().getUrl());
        PageReference pr = ApexPages.currentPage();
        pr.setRedirect(true);
        System.debug('STATUS here 4: ' + string.valueOf(gn.Status));
        return pr;
    } //public void updatePicklists()
}