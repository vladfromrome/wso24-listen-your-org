public class SCH_Dispatcher implements Schedulable {
    private static final String CHRONEXP_00 = '0 0 0/1 1/1 * ? *';
    private static final String CHRONEXP_05 = '0 5 0/1 1/1 * ? *';
    private static final String CHRONEXP_10 = '0 10 0/1 1/1 * ? *';
    private static final String CHRONEXP_15 = '0 15 0/1 1/1 * ? *';
    private static final String CHRONEXP_20 = '0 20 0/1 1/1 * ? *';
    private static final String CHRONEXP_25 = '0 25 0/1 1/1 * ? *';
    private static final String CHRONEXP_30 = '0 30 0/1 1/1 * ? *';
    private static final String CHRONEXP_35 = '0 35 0/1 1/1 * ? *';
    private static final String CHRONEXP_40 = '0 40 0/1 1/1 * ? *';
    private static final String CHRONEXP_45 = '0 45 0/1 1/1 * ? *';
    private static final String CHRONEXP_50 = '0 50 0/1 1/1 * ? *';
    private static final String CHRONEXP_55 = '0 55 0/1 1/1 * ? *';
    
    private static String APEXJOB_NAME = SCH_Dispatcher.class.getName();
    private static final String APEXJOB_NAME_00 = APEXJOB_NAME+'00';
    private static final String APEXJOB_NAME_05 = APEXJOB_NAME+'05';
    private static final String APEXJOB_NAME_10 = APEXJOB_NAME+'10';
    private static final String APEXJOB_NAME_15 = APEXJOB_NAME+'15';
    private static final String APEXJOB_NAME_20 = APEXJOB_NAME+'20';
    private static final String APEXJOB_NAME_25 = APEXJOB_NAME+'25';
    private static final String APEXJOB_NAME_30 = APEXJOB_NAME+'30';
    private static final String APEXJOB_NAME_35 = APEXJOB_NAME+'35';
    private static final String APEXJOB_NAME_40 = APEXJOB_NAME+'40';
    private static final String APEXJOB_NAME_45 = APEXJOB_NAME+'45';
    private static final String APEXJOB_NAME_50 = APEXJOB_NAME+'50';
    private static final String APEXJOB_NAME_55 = APEXJOB_NAME+'55';

    private static final Set<String> APEXJOB_NAMES = new Set<String> {
        APEXJOB_NAME_00,
        APEXJOB_NAME_05,
        APEXJOB_NAME_10,
        APEXJOB_NAME_15,
        APEXJOB_NAME_20,
        APEXJOB_NAME_25,
        APEXJOB_NAME_30,
        APEXJOB_NAME_35,
        APEXJOB_NAME_40,
        APEXJOB_NAME_45,
        APEXJOB_NAME_50,
        APEXJOB_NAME_55
    };

    private Integer MINUTE; 

    public SCH_Dispatcher(Integer minuteToRun) {
        this.MINUTE = minuteToRun;
    }

    public static void scheduleDispatchers() {
        //check if dispatchers are scheduled already
        abortScheduledDispatchers();
        
        //schedule dispatchers
        SCH_Dispatcher dispatcher00 = new SCH_Dispatcher(0);
        System.schedule(APEXJOB_NAME_00, CHRONEXP_00, dispatcher00);
        SCH_Dispatcher dispatcher05 = new SCH_Dispatcher(5);
        System.schedule(APEXJOB_NAME_05, CHRONEXP_05, dispatcher05);
        SCH_Dispatcher dispatcher10 = new SCH_Dispatcher(10);
        System.schedule(APEXJOB_NAME_10, CHRONEXP_10, dispatcher10);
        SCH_Dispatcher dispatcher15 = new SCH_Dispatcher(15);
        System.schedule(APEXJOB_NAME_15, CHRONEXP_15, dispatcher15);
        SCH_Dispatcher dispatcher20 = new SCH_Dispatcher(20);
        System.schedule(APEXJOB_NAME_20, CHRONEXP_20, dispatcher20);
        SCH_Dispatcher dispatcher25 = new SCH_Dispatcher(25);
        System.schedule(APEXJOB_NAME_25, CHRONEXP_25, dispatcher25);
        SCH_Dispatcher dispatcher30 = new SCH_Dispatcher(30);
        System.schedule(APEXJOB_NAME_30, CHRONEXP_30, dispatcher30);
        SCH_Dispatcher dispatcher35 = new SCH_Dispatcher(35);
        System.schedule(APEXJOB_NAME_35, CHRONEXP_35, dispatcher35);
        SCH_Dispatcher dispatcher40 = new SCH_Dispatcher(40);
        System.schedule(APEXJOB_NAME_40, CHRONEXP_40, dispatcher40);
        SCH_Dispatcher dispatcher45 = new SCH_Dispatcher(45);
        System.schedule(APEXJOB_NAME_45, CHRONEXP_45, dispatcher45);
        SCH_Dispatcher dispatcher50 = new SCH_Dispatcher(50);
        System.schedule(APEXJOB_NAME_50, CHRONEXP_50, dispatcher50);
        SCH_Dispatcher dispatcher55 = new SCH_Dispatcher(55);
        System.schedule(APEXJOB_NAME_55, CHRONEXP_55, dispatcher55);  
    }

    public static void abortScheduledDispatchers() {
        List<CronTrigger> cronTriggers = [
            SELECT Id, CreatedDate, NextFireTime, State, CronJobDetail.Name 
            FROM CronTrigger 
            WHERE CronJobDetail.Name IN :APEXJOB_NAMES 
            AND State NOT IN ('DELETED', 'COMPLETE', 'ERROR')
        ];
        for (CronTrigger cTrigger: cronTriggers)
            System.abortJob(cTrigger.Id);
    }

    public void execute(SchedulableContext sc) {
        System.debug('SCH_Dispatcher.execute() - MINUTE: ' + MINUTE);
        switch on MINUTE {
            when 0 {
                System.enqueueJob(new QB_ProduceMetrics());
            }
            when 5 {
                
            }
            when 10 {
                
            }
            when 15 {
                System.enqueueJob(new QB_ProduceMetrics());
            }
            when 20 {
                
            }
            when 25 {
                
            }
            when 30 {
                System.enqueueJob(new QB_ProduceMetrics());
            }
            when 35 {
                
            }
            when 40 {
                
            }
            when 45 {
                System.enqueueJob(new QB_ProduceMetrics());
            }
            when 50 {
                
            }
            when 55 {
                
            }
        }
    }
}