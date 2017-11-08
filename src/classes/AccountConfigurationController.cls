/**
 * Created by krizia on 11/2/17.
 */

public with sharing class AccountConfigurationController {
    public Id accountId;
    private final Account acc;
    private final Account a;
    public Integer generalPriorityDays { get; set; }

    public AccountConfigurationController(ApexPages.StandardController stdController) {
        a = (Account)stdController.getRecord();
        System.debug('AccountConfigurationController::: a: ' + string.valueOf(a));

        Id recordId = ApexPages.CurrentPage().getParameters().get('Id');
        System.debug('AccountConfigurationController::: recordId: ' + string.valueOf(recordId));
        acc = [SELECT Id, Name
                FROM Account
                WHERE Id =: recordId
                LIMIT 1];

        System.debug('AccountConfigurationController(::: constructor:: acc: ' + string.valueOf(acc));

    } //public AccountConfigurationController(ApexPages.StandardController stdController)


} //public with sharing class AccountConfigurationController