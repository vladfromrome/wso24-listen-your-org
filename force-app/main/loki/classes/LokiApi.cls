public class LokiApi {
    private static final Integer MAX_TIMEOUT_MS = 120000;
    private static final String lokiUrl = 'callout:loki';
    private static final String pushEndpoint = lokiUrl + '/loki/api/v1/push';
    

    private String logger;

    public LokiApi (String logger){
        this.logger = logger;
    }

    public class Message {
        public Long tsNano = System.currentTimeMillis() * 1000000;
        public String logLine; 
        public Map<String,String> labels;

        public Message(String logLine, Map<String,String> labels) {
            this.logLine = logLine;
            this.labels = labels;
        }

        public Message(String logLine) {
            this.logLine = logLine;
        }

        public Message(Map<String,String> labels) {
            this.labels = labels;
        }
    }

    public class QB_Loki implements Queueable,Database.AllowsCallouts {
        private String logger;
        private List<Message> messages;

        public QB_Loki(String logger, List<Message> messages) {
            this.logger = logger;
            this.messages = messages;
        }

        public void execute(QueueableContext qc) {
            new LokiApi(logger).logMessages(messages);
        }
    }

    public void logAsync(String line) {
        log(new List<String>{line});
    }

    public void logAsync(List<String> lines) {
        List<Message> messages = new List<Message>();
        for (String line: lines) {
            messages.add(new Message(line));
        }
        System.enqueueJob(new QB_Loki(this.logger, messages));
    }

    public void log(String line) {
        log(new List<String>{line});
    }

    public void log(List<String> lines) {
        List<Message> messages = new List<Message>();
        for (String line: lines) {
            messages.add(new Message(line));
        }
        logMessages(messages);
    }

    public void logMessage(Message message){
        logMessages(new List<Message>{message});
    }

    public void logMessages(List<Message> messages){
        LokiSchema lokiBody = new LokiSchema(this.logger,messages);
        System.debug('requestBody: ' + JSON.serializePretty(lokiBody));
        String requestBody = JSON.serialize(lokiBody);
        HttpRequest request = new HttpRequest();
        request.setTimeout(MAX_TIMEOUT_MS);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setEndpoint(pushEndpoint);
        request.setBody(requestBody);
        Http http = new Http();

        HttpResponse resp =  http.send(request);
        System.debug('ResponseStatus: ' + resp.getStatusCode() + ' ' + resp.getStatus());
        System.debug('Response: ' + ' ' + resp.getBody());
    }

}