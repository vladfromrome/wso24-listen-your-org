public class QB_ProduceMetrics implements Queueable,Database.AllowsCallouts  {

    private class Metric {
        String name;
        Integer value;
    }

    private Map<String, Integer> metricMap;

    public void execute(QueueableContext context) {
        retrieveLimitsAndCurrentValues();
        sendMetricsToLoki();
    }

    private void retrieveLimitsAndCurrentValues() {
        //Storing limits in a different format, as System.OrgLimit is not serializable - happens during processing of Queueable
        metricMap = new Map<String,Integer>();
        //OrgLimits can't be accessed in test classes - throws internal error
        //Getting the map, as List contains duplicates
        Map<String, System.OrgLimit> currentOrgLimits = 
            (Test.isRunningTest()) ? 
                new Map<String, System.OrgLimit>() 
                : OrgLimits.getMap();
        for (System.OrgLimit currentLimit : currentOrgLimits.values()) {
            metricMap.put(currentLimit.getName() + 'Limit', currentLimit.getLimit());
            metricMap.put(currentLimit.getName() + 'Value', currentLimit.getValue());
        }
        if (Test.isRunningTest()) {
            metricMap.put('TestLimitName', 0);
        }
    }

    private void sendMetricsToLoki(){
        List<String> logLines = new List<String>();
        for (String key : metricMap.keySet()) {
            Metric metric = new Metric();
            metric.name = key;
            metric.value = metricMap.get(key);
            logLines.add(JSON.serialize(metric));
        }
        LokiApi loki = new LokiApi('metrics');
        loki.log(logLines);
    }
}