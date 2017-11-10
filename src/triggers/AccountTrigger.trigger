/**
 * Created by krizia on 11/10/17.
 */

trigger AccountTrigger on Account (before insert, before update, before delete, after insert, after update, after delete, after undelete) {


    if(AccountTriggerHandler.firstRun){


        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                System.debug('AccountTrigger::: before insert');
            }
            else if (Trigger.isUpdate) {
                System.debug('AccountTrigger::: before update');
            }
            else {

            }
        } //(Trigger.isBefore)
        else {
            if (Trigger.isInsert) {
                System.debug('AccountTrigger::: after insert');
                AccountTriggerHandler.defaultEmailAddressContact(Trigger.new);
            }
            else if (Trigger.isUpdate) {
                System.debug('AccountTrigger::: after update');
                AccountTriggerHandler.defaultEmailAddressContact(Trigger.new);
            }
            else {

            }

            AccountTriggerHandler.firstRun = false;
        } //(Trigger.isAfter)

    }
}