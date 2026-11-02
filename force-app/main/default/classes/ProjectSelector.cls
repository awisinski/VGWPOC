/**
 * Centralised SOQL for the Project Foundation module.
 */
public with sharing class ProjectSelector {

    /**
     * Counts tasks per project and status.
     * Each row exposes aliases: projectId, status, cnt.
     */
    public static List<AggregateResult> countTasksByProjectAndStatus(Set<Id> projectIds) {
        return [
            SELECT Project__c projectId, Status__c status, COUNT(Id) cnt
            FROM Project_Task__c
            WHERE Project__c IN :projectIds
            GROUP BY Project__c, Status__c
        ];
    }

    public static Map<Id, Project__c> getProjectsByIds(Set<Id> projectIds) {
        return new Map<Id, Project__c>([
            SELECT Id, Name, Status__c, Progress__c
            FROM Project__c
            WHERE Id IN :projectIds
        ]);
    }
}
