trigger ProjectTaskTrigger on Project_Task__c (after insert, after update, after delete, after undelete) {
    ProjectTaskTriggerHandler.handle(Trigger.new, Trigger.oldMap, Trigger.operationType);
}
