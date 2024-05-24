global class Telemetry {
    @TestVisible static Map<String,Span> spanById = new Map<String,Span>();
    @TestVisible static Map<String,Set<String>> childSpanIdsByParentId = new Map<String,Set<String>>();

    @TestVisible static Span parentSpan;
    @TestVisible static Span rootSpan;
    private static Integer counter = 0;

    private static final String CURRENT_REQUEST_ID = System.Request.getCurrent().getRequestId();

    private Type apexType;
    private String className;
    private Map<String, String> rootAttributes = new Map<String, String>();

    global Telemetry(Type apexType) {
        this.className = apexType.getName();
        if (rootSpan == null) {
            rootSpan = constructRootSpan();
            spanById.put(rootSpan.spanId, rootSpan);
            parentSpan = rootSpan;
        }
    }

    private class CustomException extends Exception {}

    global void addRootAttributes(Map<String, Object> attributes) {
        for (String key: attributes.keySet()) {
            this.rootAttributes.put(key, String.valueOf(attributes.get(key)));
        }
    }

    global Span startSpan(String name) {
        //create new span, make it the current parent.
        counter++;
        String countStr = String.valueOf(counter);
        Span newSpan = new Span(name, className);
        newSpan.spanId = parentSpan.spanId + '::' + countStr + '::' + name;
        newSpan.traceId = rootSpan.traceId;
        newSpan.parentSpanId = parentSpan.spanId;

        spanById.put(newSpan.spanId, newSpan);
        Set<String> childSpanIds = childSpanIdsByParentId.get(parentSpan.spanId);
        if (childSpanIds==null) {
            childSpanIds = new Set<String>();
            childSpanIdsByParentId.put(parentSpan.spanId, childSpanIds);
        }
        childSpanIds.add(newSpan.spanId);
        parentSpan = newSpan;
        return newSpan;
    }

    public void endSpan(Span span) {
        //close children spans
        //make parent of this span the current parent.

        Set<String> childSpanIds = childSpanIdsByParentId.get(span.spanId);
        if (childSpanIds!=null) {
            for (String childId: childSpanIds) {
                Span child = spanById.get(childId);
                if (child.endTs == null)
                child.setEndValues();
            }
        }
        span.setEndValues();
        parentSpan = spanById.get(span.parentSpanId);
    }

    global void logSpansIfParentIsRoot() {
        //if parent is the root span 
        //close it and send
        //update tracingCache, set ts of last root - to be able to set startTs of next root.

        if (parentSpan.spanId != rootSpan.spanId)
            return;

        insertLogs(spanById.values());

        rootSpan = null;
        parentSpan = null;
        spanById = new Map<String,Span>();
        childSpanIdsByParentId = new Map<String,Set<String>>();
    }

    private void insertLogs(List<Span> spans) {
        String[] tlLines = new String[] {};
        for (Span s: spanById.values()) {
            if (s.endTs == null)
                s.setEndValues();
            tlLines.add( s.getTelemetryString() + this.getRootAttributesString());
        }
        new LokiApi('trace').logAsync(tlLines);
    }

    private Span constructRootSpan() {
        //check in cache the last logged root span. add to that one if it's open.
        // if it's closed get it's timestamp and log new one.
        Integer randomInt = randomInt();
        Span newRootSpan = new Span(className, className);
        newRootSpan.spanId = CURRENT_REQUEST_ID + '::' + String.valueOf(randomInt);
        newRootSpan.traceId = CURRENT_REQUEST_ID;
        //update cache with new root span id, rootSpanStatus - open, + basic attributes.
        return newRootSpan;
    }

    private String getRootAttributesString(){
        String attributesString = '';
        for (String key: this.rootAttributes.keySet()){
            String value = this.rootAttributes.get(key);
            attributesString += ' ' + key + '="' + value + '"';
        }
        return attributesString;
    }

    private Integer randomInt() {
        Integer min = 1;
        Integer max = 1000000000;
        Integer randomInt = (Integer)Math.floor(Math.random() * (max - min + 1)) + min;
        return randomInt;
    }

    global class Span {
        String name;
        String className;
        String traceId;
        String spanId;
        String parentSpanId;
        Long startTs = System.currentTimeMillis();
        Long endTs;
        Integer startCpuTime = Limits.getCpuTime();
        Integer endCpuTime;
        Integer startHeapSize = Limits.getHeapSize();
        Integer endHeapSize;
        Integer startQueries = Limits.getQueries();
        Integer endQueries;
        Integer startQueueableJobs = Limits.getQueueableJobs();
        Integer endQueueableJobs;
        Integer startPublishImmediateDML = Limits.getPublishImmediateDML();
        Integer endPublishImmediateDML;
        Integer startDMLStatements = Limits.getDMLStatements();
        Integer endDMLStatements;
        Integer startDMLRows = Limits.getDmlRows();
        Integer endDMLRows;
        Integer startQueryRows = Limits.getQueryRows();
        Integer endQueryRows;

        Map<String,String> attributes = new Map<String,String>();

        global Span(String name, String className) {
            this.name = name.remove('"').deleteWhitespace();
            this.className = className;
        }

        global void addAtribute(String key, Object value) {
            if (value != null)
                this.attributes.put(key, String.valueOf(value));
            else
                this.attributes.put(key, '');
        }

        public void setEndValues(){
            this.endTs = System.currentTimeMillis();
            this.endCpuTime = Limits.getCpuTime();
            this.endHeapSize = Limits.getHeapSize();
            this.endQueries = Limits.getQueries();
            this.endQueueableJobs = Limits.getQueueableJobs();
            this.endPublishImmediateDML = Limits.getPublishImmediateDML();
            this.endDMLStatements = Limits.getDMLStatements();
            this.endDMLRows = Limits.getDMLRows();
            this.endQueryRows = Limits.getQueryRows();
        }

        public String getTelemetryString() {
            try {
                String telemetry = String.format(
                    'spanName="{0}" traceId="{1}" spanId="{2}" parentSpanId="{3}" startTs="{4}" endTs="{5}" duration="{6}" cpuTime="{7}" queries="{8}" heapSize="{9}" queueableJobs="{10}" publishImmediateDML="{11}" dmlStatements="{12}" dmlRows="{13}" queryRows="{14}" className="{15}"',
                    new Object[] {
                        this.name,
                        this.traceId,
                        this.spanId,
                        (String.isBlank(this.parentSpanId))? '': this.parentSpanId,
                        this.startTs,
                        this.endTs,
                        this.endTs-this.startTs,
                        this.endCpuTime-this.startCpuTime,
                        this.endQueries-this.startQueries,
                        this.endHeapSize-this.startHeapSize,
                        this.endQueueableJobs-this.startQueueableJobs,
                        this.endPublishImmediateDML-this.startPublishImmediateDML,
                        this.endDMLStatements-this.startDMLStatements,
                        this.endDMLRows-this.startDMLRows,
                        this.endQueryRows-this.startQueryRows,
                        className
                    }
                );
                for (String key: attributes.keySet()) {
                    String value = attributes.get(key);
                    telemetry += ' ' + key + '="' + value + '"';
                }
                return telemetry;
            } catch (Exception e) {
                throw new Telemetry.CustomException(JSON.serialize(this));
            }
        }
    }
    
}