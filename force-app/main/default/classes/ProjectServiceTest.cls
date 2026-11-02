@IsTest
private class ProjectServiceTest {

    @TestSetup
    static void setup() {
        insert new Project__c(Name = 'Foundation', Status__c = 'Active');
    }

    private static Project__c getProject() {
        return [SELECT Id, Status__c, Progress__c FROM Project__c LIMIT 1];
    }

    @IsTest
    static void calculateProgressHandlesZeroAndRounding() {
        Assert.areEqual(0, ProjectService.calculateProgress(0, 0));
        Assert.areEqual(33, ProjectService.calculateProgress(1, 3));
        Assert.areEqual(67, ProjectService.calculateProgress(2, 3));
        Assert.areEqual(100, ProjectService.calculateProgress(4, 4));
    }

    @IsTest
    static void nextStatusTransitions() {
        Assert.areEqual('Completed', ProjectService.nextStatus('Active', 2, 2));
        Assert.areEqual('Active', ProjectService.nextStatus('Completed', 1, 2));
        Assert.areEqual('Planned', ProjectService.nextStatus('Planned', 0, 0));
        Assert.areEqual('On Hold', ProjectService.nextStatus('On Hold', 1, 3));
    }

    @IsTest
    static void recalculateIgnoresEmptyAndNullIds() {
        Test.startTest();
        ProjectService.recalculateProgress(new Set<Id>());
        ProjectService.recalculateProgress(new Set<Id>{ null });
        Test.stopTest();

        Assert.isNull(getProject().Progress__c, 'Progress should stay untouched');
    }

    @IsTest
    static void recalculateSetsProgressAndCompletes() {
        Project__c project = getProject();
        // Insert tasks with the trigger path, then recalculate explicitly.
        insert new List<Project_Task__c>{
            new Project_Task__c(Name = 'A', Project__c = project.Id, Status__c = 'Done'),
            new Project_Task__c(Name = 'B', Project__c = project.Id, Status__c = 'Done')
        };

        Test.startTest();
        ProjectService.recalculateProgress(new Set<Id>{ project.Id });
        Test.stopTest();

        Project__c result = getProject();
        Assert.areEqual(100, result.Progress__c);
        Assert.areEqual('Completed', result.Status__c);
    }

    @IsTest
    static void validationRuleRejectsEndBeforeStart() {
        Project__c bad = new Project__c(
            Name = 'Bad dates',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(-1)
        );

        Test.startTest();
        Database.SaveResult sr = Database.insert(bad, false);
        Test.stopTest();

        Assert.isFalse(sr.isSuccess(), 'End Date before Start Date must be rejected');
    }
}
