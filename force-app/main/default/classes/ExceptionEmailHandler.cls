global class ExceptionEmailHandler implements Messaging.InboundEmailHandler {
    public static final String LOGGER = 'ExceptionEmail';
    private static final String TYPE_CLASS = 'CLASS';
    private static final String TYPE_FLOW = 'FLOW';

    public class Error {
        public String subject;
        public String body;
        public String apiName;
        public String type;
        public String errorMessage;
        public String username;
        public String userId;
    }

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Error error = getErrorFromEmail(email);
        LokiApi loki = new LokiApi(LOGGER);
        loki.log(JSON.serialize(error));
        
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        result.success = true;
        return result;
    }


    public Error getErrorFromEmail(Messaging.InboundEmail email) {
        Error error = new Error();
        error.subject = email.subject;
        error.body = String.isNotEmpty(email.plainTextBody) ? email.plainTextBody : email.htmlBody.stripHtmlTags();

        String className = getClassName(error.subject);

        if (String.isNotBlank(className)) {
            error.type = TYPE_CLASS;
            error.apiName = className;

        } else {
            String flowApiName = getFlowApiName(error.body);
            error.type = TYPE_FLOW;
            error.apiName = flowApiName;
            error.errorMessage = getFlowError(error.body);
        }

        User userRecord = getUserDetails(error.body, error.type);
        error.userId = userRecord.Id;
        error.username = userRecord.UserName;

        return error;

    }

    private String getClassName(String subject) {
        //Developer script exception from My Org : MyClass for job ID 7072p0000CRyqeu. : The following template named my_template was not found.
        //Developer script exception from My Org : 'MyBatch' for job id '7072p0000BdYodi' : Batchable instance is too big: MyBatch
        String regex = '^(Sandbox: )?Developer script exception from [a-zA-Z0-9/s]+ (: \'|: )(\\S*)\\s?.*(\'| :).*$';
        return getValueWithRegex(subject, regex, 3).remove('\'');
    }

    private String getFlowApiName(String body) {
        return getValueWithRegex(body, '^.*Flow API Name: (.*)$');
        
    }

    private User getUserDetails(String body, String type) {
        String userId = (type == TYPE_CLASS) ? 
            getUserIdFromClassEmail(body) : getUserIdFromFlow(body);

        if (String.isBlank(userId)) {
            userId = UserInfo.getUserId();
        }

        return retrieveUserById(userId);
    }

    private User retrieveUserById(String userId) {
        return [SELECT Id, Name, UserName FROM User WHERE Id = :userId LIMIT 1];

    }

    private String getUserIdFromFlow(String body){
        String userInfo = getValueWithRegex(body, '^ *Current User: (.*)$');
        return getUserIdFromUserInfoLine(userInfo);
    }

    private String getUserIdFromUserInfoLine(String currentUser){
        return getValueWithRegex(currentUser, '^.*\\(([a-zA-Z0-9]{15})\\)$');
    }

    private String getUserIdFromClassEmail(String body) {
        return getValueWithRegex(body,'^.*([a-zA-Z0-9]{15})/[a-zA-Z0-9]{15}$');
    }

    private String getValueWithRegex(String text, String regex){
        return getValueWithRegex(text, regex, 1);
    }

    private String getValueWithRegex(String text, String regex, Integer groupNumber){
        String value='';
        Pattern p = pattern.compile(regex);
        String[] lines = text.split('\n');
        for (String line: lines) {
            Matcher m = p.matcher(line);
            if (m.matches())
            {
                value = m.group(groupNumber);
            }
            if (String.isNotBlank(value)) break;
        }
        return value;
    }

    private String getFlowError(String body) {
        String errorMessage = '';
        String[] lines = body.split('\n');

        Pattern patternEng = pattern.compile('^ *Error Occurred: (.*)$');

        for (Integer i = lines.size()-1; i > -1; i--) {
            String line = lines[i];
            Matcher matcherEng = patternEng.matcher(line);
            if (matcherEng.matches())
                errorMessage = matcherEng.group(1);
            if (String.isNotBlank(errorMessage)) {
                for (Integer j=i+1; j<lines.size(); j++){
                    errorMessage += '\n' + lines[j];
                }
                break;
            }
        }
        return errorMessage;
    }
}