public class LokiSchema {
    private static final Organization currentOrg = [SELECT Id, Name FROM Organization LIMIT 1];
    private static final String ORG_ID = currentOrg.Name.deleteWhitespace()+'-'+currentOrg.Id;
    
    Stream[] streams;

    public class Stream {
        Map<String, String> stream;
        Object[][] values;
    }

    public LokiSchema (String logger, LokiApi.Message message) {
        LokiSchema s = new LokiSchema(logger, new List<LokiApi.Message>{message});
        this.streams = s.streams;
    }

    public LokiSchema (String logger, List<LokiApi.Message> messages) {
        Stream stream = new Stream();
        this.streams = new List<Stream>{stream};

        stream.stream = new Map<String, String>{'logger' => logger, 'orgId' => ORG_ID};
        stream.values = new List<Object[]>{};

        for (LokiApi.Message message : messages) {
            Object[] values = new List<Object>();
            values.add(String.valueOf(message.tsNano));
            values.add(message.logLine ?? '');
            if (message.labels != null)
                values.add(message.labels);
            stream.values.add(values);
        }
    }

}