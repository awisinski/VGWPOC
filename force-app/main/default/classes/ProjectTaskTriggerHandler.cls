/**
 * Trigger handler for Project_Task__c.
 * Collects affected projects and asks ProjectService to recalculate them.
 */
public with sharing class ProjectTaskTriggerHandler {

    public static void handle(
        List<Project_Task__c> newList,
        Map<Id, Project_Task__c> oldMap,
        System.TriggerOperation operation
    ) {
        Set<Id> projectIds = new Set<Id>();

        switch on operation {
            when AFTER_INSERT, AFTER_UNDELETE {
                for (Project_Task__c task : newList) {
                    projectIds.add(task.Project__c);
                }
            }
            when AFTER_UPDATE {
                for (Project_Task__c task : newList) {
                    Project_Task__c oldTask = oldMap.get(task.Id);
                    if (task.Status__c != oldTask.Status__c || task.Project__c != oldTask.Project__c) {
                        projectIds.add(task.Project__c);
                        projectIds.add(oldTask.Project__c);
                    }
                }
            }
            when AFTER_DELETE {
                for (Project_Task__c task : oldMap.values()) {
                    projectIds.add(task.Project__c);
                }
            }
        }

        ProjectService.recalculateProgress(projectIds);
    }
}
