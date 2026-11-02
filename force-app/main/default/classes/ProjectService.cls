/**
 * Business logic for Project__c.
 * Keeps Progress__c in sync with the share of Done tasks and
 * moves the project to Completed when every task is Done.
 */
public with sharing class ProjectService {

    public static final String TASK_STATUS_DONE = 'Done';
    public static final String PROJECT_STATUS_ACTIVE = 'Active';
    public static final String PROJECT_STATUS_COMPLETED = 'Completed';

    public static void recalculateProgress(Set<Id> projectIds) {
        Set<Id> ids = new Set<Id>(projectIds);
        ids.remove(null);
        if (ids.isEmpty()) {
            return;
        }

        Map<Id, Integer> totalByProject = new Map<Id, Integer>();
        Map<Id, Integer> doneByProject = new Map<Id, Integer>();
        for (AggregateResult row : ProjectSelector.countTasksByProjectAndStatus(ids)) {
            Id projectId = (Id) row.get('projectId');
            Integer cnt = (Integer) row.get('cnt');
            increment(totalByProject, projectId, cnt);
            if ((String) row.get('status') == TASK_STATUS_DONE) {
                increment(doneByProject, projectId, cnt);
            }
        }

        List<Project__c> toUpdate = new List<Project__c>();
        for (Project__c project : ProjectSelector.getProjectsByIds(ids).values()) {
            Integer total = totalByProject.containsKey(project.Id) ? totalByProject.get(project.Id) : 0;
            Integer done = doneByProject.containsKey(project.Id) ? doneByProject.get(project.Id) : 0;

            Decimal progress = calculateProgress(done, total);
            String status = nextStatus(project.Status__c, done, total);

            if (progress != project.Progress__c || status != project.Status__c) {
                toUpdate.add(new Project__c(Id = project.Id, Progress__c = progress, Status__c = status));
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    @TestVisible
    private static Decimal calculateProgress(Integer done, Integer total) {
        if (total == null || total == 0) {
            return 0;
        }
        return (Decimal.valueOf(done) * 100 / total).setScale(0, System.RoundingMode.HALF_UP);
    }

    @TestVisible
    private static String nextStatus(String currentStatus, Integer done, Integer total) {
        if (total > 0 && done == total) {
            return PROJECT_STATUS_COMPLETED;
        }
        if (currentStatus == PROJECT_STATUS_COMPLETED) {
            // A task was reopened or added to a completed project.
            return PROJECT_STATUS_ACTIVE;
        }
        return currentStatus;
    }

    private static void increment(Map<Id, Integer> counter, Id key, Integer value) {
        Integer current = counter.containsKey(key) ? counter.get(key) : 0;
        counter.put(key, current + value);
    }
}
