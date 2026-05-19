trigger ClosedOpportunityTrigger on Opportunity (after insert, after update) {
    if (Trigger.isInsert && Trigger.isAfter) {
        List<Task> taskInsertList = new List<Task>();
        for (Opportunity opp : Trigger.new) {
            if (opp.StageName == 'Closed Won') {
                Task tsk = new Task();
                tsk.Subject = 'テスト ToDo をフォローアップする';
                tsk.whatId = opp.Id;
                taskInsertList.add(tsk);
            }
        }

        if (taskInsertList.size() > 0) {
            insert taskInsertList;
        }
    } else if (Trigger.isUpdate && Trigger.isAfter) {
        List<Task> taskInsertList = new List<Task>();
        for (Opportunity opp : Trigger.new) {
            if (opp.StageName == 'Closed Won') {
                Task tsk = new Task();
                tsk.Subject = 'テスト ToDo をフォローアップする';
                tsk.whatId = opp.Id;
                taskInsertList.add(tsk);
            }
        }

        if (taskInsertList.size() > 0) {
            insert taskInsertList;
        }
    }
}