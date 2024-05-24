public class TA_AccountFields implements TriggerAction.BeforeUpdate {
    private class CustomException extends Exception {}

    private class QB_AccountError implements Queueable {

        public void execute(QueueableContext context) {
            throw new CustomException('this is a test exception');
        }
    }

    public void beforeUpdate(List<Account> newList, List<Account> oldList) {
        Map<Id,Account> oldMap = new Map<Id,Account>(oldList);
        Contact defaultContact = [SELECT Id, Name FROM Contact WHERE LastName = 'Default' LIMIT 1];
        defaultContact = [SELECT Id, Name FROM Contact WHERE LastName = 'Default' LIMIT 1];
        defaultContact = [SELECT Id, Name FROM Contact WHERE LastName = 'Default' LIMIT 1];
        System.enqueueJob(new QB_AccountError());
        createRecordInFuture();
        
    }

    @Future
    public static void createRecordInFuture(){
        Task t = new Task(Subject='asdf');
        insert t;
    }
}