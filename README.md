# Listen to your org - Wir Sind Ohana talk demo
See below the setup and features description. Talk slides here: [link](https://docs.google.com/presentation/d/1ApUJQtDD5aWsIkgEO_EUOwitVC-QTFF18iMywiKTKms/edit?usp=sharing)

## Features

### Sending logs to Grafana Loki

See code in `force-app/main/loki`

- Initialize the API wrapper class with logger name. E.g. `LokiApi l = new LokiApi('test');` this class instance will produce lines with label _"logger" = "test"_. Find them in grafana with query `{logger="test"}`
- LokiSchema always adds label _**orgId**_ - this way you know which org produced the log.
- Documentation for LogQL query language at https://grafana.com/docs/loki/latest/query/log_queries/

Send plain text
```
LokiApi.Message m = new LokiApi.Message('hello world');
LokiApi l = new LokiApi('test');
l.logMessage(m);
```
Send json
```
Map<String,Object> myMap = new Map<String,Object>{'key1'=>'value1','key2'=>111};
LokiApi.Message m = new LokiApi.Message(JSON.serialize(myMap));
LokiApi l = new LokiApi('test');
l.logMessage(m);
```

### Capturing and logging Error Emails
- Go to Setup / Email Services -> New Email Service
    - Name: ExceptionEmailService, Apex Class: ExceptionEmailHandler, Accept Email From: leave blank -> Save
- in the related list Email Addresses - > New Email Address
    - Name: ExceptionEmailService, address: ExceptionEmailService, accept email from: make blank -> Save
- Copy the email address from the newly created address
- Go to Setup / Apex Exception Email -> paste the address to External Email Addresses, click Save
- Now if the error email is produced by the org - it will be redirected to the apex class ExceptionEmailHandler that will parse the content and send structured logs to grafana
- n.b. Error email delivery is not guaranteed in sandboxes - so for testing send that email from your inbox or use the class [ErrorGenerator](https://github.com/vladfromrome/wso24-listen-your-org/blob/main/force-app/main/default/classes/ErrorGenerator.cls) to imitate errors and log them in grafana

### Monitoring Salesforce Limit Metrics
- class _force-app/main/default/classes/QB_ProduceMetrics.cls_ is launched every 15 min by the scheduled apex class [SCH_Dispatcher](https://github.com/vladfromrome/wso24-listen-your-org/blob/main/force-app/main/default/classes/SCH_Dispatcher.cls)
- current limits and consumption values are obtained from the method [OrgLimits.getMap()](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_System_OrgLimits.htm#apex_System_OrgLimits_getMap) and sent to Grafana

### Observing trigger actions execution
- As the base here we have [Trigger Actions Framework](https://github.com/mitchspano/apex-trigger-actions-framework) - see folder _force-app/main/trigger-actions_
- Class [Telemetry](https://github.com/vladfromrome/wso24-listen-your-org/blob/main/force-app/main/default/classes/Telemetry.cls) is producing traces and logs them in grafana
- Class [MetadataTriggerHandler](https://github.com/vladfromrome/wso24-listen-your-org/blob/main/force-app/main/trigger-actions/classes/MetadataTriggerHandler.cls) is using the Telemetry class to log start and end time and limits consumption of each trigger action
- Example code and settings for trigger actions is in folders _force-app/main/opportunity_ and _force-app/main/account_


## Setup

### Get Grafana trial org and API access token
- Sign-up here - https://grafana.com/auth/sign-up/create-user
- Go to https://grafana.com/ , open "My Account"
- Next to Loki click "Details"
- Save your loki URL and username in a safe place
- Next to Password:Your Grafana.com API Token. click "Generate Now"
- Save your Loki access token in a safe place

### Scratch Org Setup
**Create scratch org**
```
DEVHUB=my-dev-hub
ALIAS=my-new-scratch
sf org:create:scratch \
		--definition-file config/project-scratch-def.json \
		--wait 100 \
		--duration-days 30 \
		--target-dev-hub $(DEVHUB) \
		--set-default \
		--alias=$(ALIAS)
```
**Push source**
```
sf project deploy start
```
**Assign permset**
```
sf org assign permset --name default
```
**Save API token in the loki_auth External Credential**
- Go to Setup / Named Credentials
- Click Loki
- Update URL to point to your loki URL
- Navigate to the related loki_auth External Credentials
- In the Principals list - edit the auth parameter
- Use Loki User Id and API access token as Username and Password
- Click Save

**Test Logger**
- Execute this code as anonymous apex to send a log line to Grafana.
```
LokiApi.Message m = new LokiApi.Message('hello world');
LokiApi l = new LokiApi('test');
l.logMessage(m);
```
- Open Grafana (My Account -> Grafana -> Launch)
- In the main menu (upper left) click Explore
- run the this query to find the log 
```
{logger="test"}
```
**Schedule metrics logging**
```
sf apex run -f scripts/schedule.apex
```

