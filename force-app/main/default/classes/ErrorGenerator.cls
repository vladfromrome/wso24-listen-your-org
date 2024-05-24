public class ErrorGenerator {
    private static List<User> users = new List<User>{
        new User(Id='00557000000000A001', Username = 'andy@myscratch.com'),
        new User(Id='00557000000000B002', Username = 'bob@myscratch.com'),
        new User(Id='00557000000000C003', Username = 'clara@myscratch.com')
    };

    private static String emailBody = 'Apex script unhandled exception by user/organization: 0053X00000AZ394/00D3X000001u67t\n\nFailed to invoke future method \'public static void runWarehouseEquipmentSync()\' on class \'WarehouseCalloutService\' for job id \'7073X00008IZkXS\'\n\ncaused by: System.DmlException: Upsert failed. First exception on row 0; first error: DUPLICATE_EXTERNAL_ID, Warehouse SKU: more than one record found for external id field: [01t3X00000FOmEpQAL, 01t3X00000FOlgdQAD, 01t3X00000FOlzlQAD, 01t3X00000FOljkQAD]: [Warehouse_SKU__c]\n\nClass.WarehouseCalloutService.runWarehouseEquipmentSync: line 38, column 1';

    //ErrorGenerator.random();
    public static void random() {
        List<String> errors = new List<String>();
        for (Integer i = 0; i< randomInt(1, 10); i++){
            User user = users[randomInt(0, users.size() - 1)];
            Integer randomInt = randomInt(1, 5);
            String className = 'IssueClass'+randomInt;
            ExceptionEmailHandler.Error error = getError(className, user);
            
            errors.add(JSON.serialize(error));
        }

        LokiApi loki = new LokiApi(ExceptionEmailHandler.LOGGER);
        loki.log(errors);
        
    }

    //ErrorGenerator.fromOneClass(5);
    //ErrorGenerator.fromOneClass(16);
    public static void fromOneClass(Integer count) {
        Integer i = randomInt(1, 5);
        String className = 'IssueClass'+i;
        List<String> errors = new List<String>();
        for(Integer j = 0; j < count; j++){
            User user = users[randomInt(0, users.size() - 1)];
            ExceptionEmailHandler.Error error = getError(className, user);
            errors.add(JSON.serialize(error));
        }
        LokiApi loki = new LokiApi(ExceptionEmailHandler.LOGGER);
        loki.log(errors);
    }

    private static ExceptionEmailHandler.Error getError(String className, User user){
        ExceptionEmailHandler.Error error = new ExceptionEmailHandler.Error();
        error.subject = 'Developer script exception from MyScratch : '+className+' : Apex CPU time limit exceeded';
            error.body = 'Developer script exception from MyScratch : '+className+' : Apex CPU time limit exceeded';
            error.apiName = className;
            error.body = emailBody;
            error.username = user.Username;
            error.userId = user.Id;
            error.type = 'CLASS';
            error.errorMessage = 'System.DmlException: Upsert failed. First exception on row 0; first error: DUPLICATE_EXTERNAL_ID, Warehouse SKU: more than one record found for external id field: [01t3X00000FOmEpQAL, 01t3X00000FOlgdQAD, 01t3X00000FOlzlQAD, 01t3X00000FOljkQAD]: [Warehouse_SKU__c]';
        return error;
    }

    private static Integer randomInt(Integer min, Integer max) {
        Integer randomInt = (Integer)Math.floor(Math.random() * (max - min + 1)) + min;
        return randomInt;
    }
}