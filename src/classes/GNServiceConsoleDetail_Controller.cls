/**
 * Created by krizia on 10/27/17.
 */

public with sharing class GNServiceConsoleDetail_Controller {
    public Case myCase {get; set; }
    public Case myCaseDetails { get; set; }


    public GNServiceConsoleDetail_Controller(ApexPages.StandardController stdController) {
        myCase = (Case) stdController.getRecord();
        myCaseDetails = [SELECT Id, CaseNumber, AccountId, Account.Name, Owner.Name, Status
        FROM Case
        WHERE Id =: myCase.Id];

    }
}