@IsTest
private class ProjectTaskTriggerHandlerTest {

    @TestSetup
    static void setup() {
        insert new List<Project__c>{
            new Project__c(Name = 'Alpha', Status__c = 'Active'),
            new Project__c(Name = 'Beta', Status__c = 'Active')
        };
    }

    private static Project__c project(String name) {
        return [SELECT Id, Status__c, Progress__c FROM Project__c WHERE Name = :name];
    }

    @IsTest
    static void insertCalculatesProgress() {
        Id alphaId = project('Alpha').Id;

        Test.startTest();
        insert new List<Project_Task__c>{
            new Project_Task__c(Name = 'T1', Project__c = alphaId, Status__c = 'Done'),
            new Project_Task__c(Name = 'T2', Project__c = alphaId, Status__c = 'In Progress'),
            new Project_Task__c(Name = 'T3', Project__c = alphaId, Status__c = 'Not Started'),
            new Project_Task__c(Name = 'T4', Project__c = alphaId, Status__c = 'Done')
        };
        Test.stopTest();

        Project__c result = project('Alpha');
        Assert.areEqual(50, result.Progress__c);
        Assert.areEqual('Active', result.Status__c);
    }

    @IsTest
    static void updateToDoneCompletesProjectAndReopenReactivates() {
        Id alphaId = project('Alpha').Id;
        Project_Task__c task = new Project_Task__c(Name = 'Only', Project__c = alphaId, Status__c = 'In Progress');
        insert task;

        Test.startTest();
        // Update only the changed field: Project__c is a non-reparentable master-detail.
        update new Project_Task__c(Id = task.Id, Status__c = 'Done');
        Assert.areEqual('Completed', project('Alpha').Status__c);
        Assert.areEqual(100, project('Alpha').Progress__c);

        update new Project_Task__c(Id = task.Id, Status__c = 'In Progress');
        Test.stopTest();

        Project__c result = project('Alpha');
        Assert.areEqual('Active', result.Status__c);
        Assert.areEqual(0, result.Progress__c);
    }

    @IsTest
    static void updateWithoutStatusChangeDoesNothing() {
        Id alphaId = project('Alpha').Id;
        Project_Task__c task = new Project_Task__c(Name = 'Rename me', Project__c = alphaId, Status__c = 'Done');
        insert task;

        Test.startTest();
        update new Project_Task__c(Id = task.Id, Name = 'Renamed');
        Test.stopTest();

        Assert.areEqual(100, project('Alpha').Progress__c);
    }

    @IsTest
    static void deleteAndUndeleteRecalculate() {
        Id betaId = project('Beta').Id;
        Project_Task__c done = new Project_Task__c(Name = 'Done', Project__c = betaId, Status__c = 'Done');
        Project_Task__c open = new Project_Task__c(Name = 'Open', Project__c = betaId, Status__c = 'Not Started');
        insert new List<Project_Task__c>{ done, open };
        Assert.areEqual(50, project('Beta').Progress__c);

        Test.startTest();
        delete open;
        Assert.areEqual(100, project('Beta').Progress__c);
        Assert.areEqual('Completed', project('Beta').Status__c);

        undelete open;
        Test.stopTest();

        Project__c result = project('Beta');
        Assert.areEqual(50, result.Progress__c);
        Assert.areEqual('Active', result.Status__c);
    }

    @IsTest
    static void bulkInsertAcrossProjects() {
        Id alphaId = project('Alpha').Id;
        Id betaId = project('Beta').Id;
        List<Project_Task__c> tasks = new List<Project_Task__c>();
        for (Integer i = 0; i < 200; i++) {
            tasks.add(new Project_Task__c(
                Name = 'Bulk ' + i,
                Project__c = Math.mod(i, 2) == 0 ? alphaId : betaId,
                Status__c = Math.mod(i, 4) < 2 ? 'Done' : 'Not Started'
            ));
        }

        Test.startTest();
        insert tasks;
        Test.stopTest();

        Assert.areEqual(50, project('Alpha').Progress__c);
        Assert.areEqual(50, project('Beta').Progress__c);
    }
}
