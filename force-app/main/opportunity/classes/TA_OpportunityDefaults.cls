public class TA_OpportunityDefaults implements TriggerAction.BeforeUpdate {
    public void beforeUpdate(List<Opportunity> newList, List<Opportunity> oldList) {
        Map<Id,Opportunity> oldMap = new Map<Id,Opportunity>(oldList);
        Contact defaultContact = [SELECT Id, Name FROM Contact WHERE LastName = 'Default' LIMIT 1];
        // for (Integer i = 0; i < 16; i++{
        //     Contact defaultContact = [SELECT Id, Name FROM Contact WHERE LastName = 'Default' LIMIT 1];
        // }
        for (Opportunity newOpp: newList) {
            Opportunity oldOpp = oldMap.get(newOpp.Id);
            if (newOpp.Name != oldOpp.Name) {
                newOpp.Description = 'This is a new opportunity with the name ' + newOpp.Name;
                if (defaultContact != null) {
                    newOpp.Description =+ '. Default contact: ' + defaultContact.Name;
                }
            }
        }
    }
}