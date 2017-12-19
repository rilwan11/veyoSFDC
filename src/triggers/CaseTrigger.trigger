/**
 * Created on 10/19/17.
 * All triggered options from a Case (Grievance Note)
 */

trigger CaseTrigger on Case (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    if(CaseTriggerHandler.firstRun){


        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                System.debug('CaseTrigger::: before insert');
                CaseTriggerHandler.setDueDate(Trigger.new, Trigger.newMap);
                CaseTriggerHandler.insertCaseTime(Trigger.new);
            }
            else if (Trigger.isUpdate) {
                System.debug('CaseTrigger::: before update');
                CaseTriggerHandler.updateCaseTime(Trigger.new, Trigger.oldMap);
            }
            else {

            }
        } //(Trigger.isBefore)
        else {
            if (Trigger.isInsert) {
                System.debug('CaseTrigger::: after insert');
                CaseTriggerHandler.insertCaseAgingHistory(Trigger.new, Trigger.oldMap);
                CaseTriggerHandler.sendAutomaticEmailsOnInsert(Trigger.new);
            }
            else if (Trigger.isUpdate) {
                System.debug('CaseTrigger::: after update');
                CaseTriggerHandler.insertCaseAgingHistory(Trigger.new, Trigger.oldMap);
                CaseTriggerHandler.sendAutomaticEmails(Trigger.new, Trigger.oldMap);
            }
            else {

            }

            CaseTriggerHandler.firstRun = false;
        } //(Trigger.isAfter)

    }
}