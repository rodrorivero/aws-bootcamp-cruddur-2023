```
                                                                                                                                  
   :7YPGGGGGP5?: JGGGGGGGGGPP5J~.  JGGGGG7  ~GGGGG5  5GGGGGGGGP5Y7:    PGGGGGGGGP5Y!.    PGGGGG:  ?GGGGG? .GGGGGGGGGGP5Y7:     
 .5BBBGGBBBBBBB^ JBGGGGGPPGGGGBBG: YBGGGB?  !BGGGGP  PBGGGGBBBBGBBBY.  GGGGGGBBBBGBBBY.  GGGGGB:  JBGGGBJ :BGGGGGPPPGGGBBBJ    
.GBGGGGGJ!^~!?J  JBGGGG5::~GGGGGB? YBGGGB?  ~BGGGGP  PGGGGBY~7PGGGGBG. GGGGGG?^75GGGGBP  GGGGGB:  JBGGGBJ :BGGGGG~.:JBGGGGB.   
^BGGGGB7         JBGGGGGGGGGGGGG5. YBGGGB?  ~BGGGGP  PGGGGB!  .GGGGGB^ GGGGGB:  .GGGGGB^ GGGGGB^  JBGGGBJ :BGGGGGGGGGGGGGG!    
.GBGGGGP?~:^~7?  JBGGGGPYGGGGGB!   !BGGGGP~^5GGGGBJ  PGGGGBJ:!5GGGGBG. GGGGGB7:!5GGGGBG. 5BGGGG5^!GGGGGB~ :BGGGGG55BGGGG5.     
 :5BBGGGBBBBBBB^ JBGGGB? :GGGGGP.   JBBGGGBBGGGBB5.  PGGGGGGBBBGBBB5:  GGGGGGBBBBGBBB5:  .5BBGGGBBGGGBB?  :BGGGGG. JBGGGG7     
   ^?5GGGGGGGPJ: JGGGGG?  ^GGGGGP.   :?5GGGGGGPJ^    5GGGGGGGGGPY?:    PGGGGGGGGGPY7:      ~Y5GGGGGP5?:   .GGGGGG.  5GGGGG7       
                                                                                                                                  
```  
# Week 2 — Distributed Tracing

## 1) Honeycomb

To implement Honeycomb using OpenTelemetry in our Flask back end, we will use OpenTelemetry SDK for Python along with the OpenTelemetry Honeycomb exporter based on the information provided on [Honeycomb.io web site](https://docs.honeycomb.io/getting-data-in/opentelemetry/python/) . Here are the steps performed:

#### 1.1) Add the OTEL (Open Telemetry) sources for provitioning it with python on our backend-flask/requirements.txt file:
```txt
opentelemetry-api 
opentelemetry-sdk 
opentelemetry-exporter-otlp-proto-http 
opentelemetry-instrumentation-flask 
opentelemetry-instrumentation-requests
```
#### 1.2) Install the OTEL SDK and the OpenTelemetry Honeycomb exporter using pip:
```txt
pip install -r requirements.txt
```
#### 1.3) Initialize the OTEL SDK and the Honeycomb exporter in our Flask backend (app.py) and instrument it by adding tracing using the @tracer.span() decorator provided by the OpenTelemetry SDK:
```py
#Honeycomb---
#Import libraries

from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

#Honeycomb---
#Initialize tracing and an exporter that can send data to Honeycomb
provider = TracerProvider()
processor = BatchSpanProcessor(OTLPSpanExporter())
provider.add_span_processor(processor)

#Add tracing for instrumentation
trace.set_tracer_provider(provider)
tracer = trace.get_tracer(__name__)

#Honeycomb---
#Initialize automatic instrumentation with Flask
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()
```
#### 1.4) Configure the variables on docker-compose.yml:
```yml
OTEL_SERVICE_NAME: "backend-flask"
OTEL_EXPORTER_OTLP_ENDPOINT: "https://api.honeycomb.io"
OTEL_EXPORTER_OTLP_HEADERS: "x-honeycomb-team=${HONEYCOMB_API_KEY}"
```
#### 1.5) Export and persist the environmental variables of your honeycomb account:

HONEYCOMB

#### 1.6) Run queries to explore traces

![image](https://user-images.githubusercontent.com/85003009/222978324-068ca95c-54cf-419a-b245-b8a662070423.png)

![image](https://user-images.githubusercontent.com/85003009/222978407-a7c27003-2af1-4efc-b291-16d2b8aef98a.png)


## 2) XRay

To instrument AWS X-Ray into our Flask application using the X-Ray daemon, we will use the AWS X-Ray SDK for Python along with the xray_recorder middleware for Flask:

#### 2.1) Add the AWS X-Ray SDK sources for provitioning it with python on our backend-flask/requirements.txt file:
```txt
aws-xray-sdk
```
#### 2.2) Install the AWS X-Ray SDK using pip:
```txt
pip install -r requirements.txt
```
#### 2.3) Configure the AWS X-Ray SDK in our Flask backend (app.py) by importing it and calling the configure() method with the daemon_address argument set to the address of the X-Ray daemon:
```py
#X-RAY-------------------
# Importing AWS X-Ray libraries
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.ext.flask.middleware import XRayMiddleware

#X-RAY-------------------
# Configure the AWS X-Ray SDK
xray_url = os.getenv("AWS_XRAY_URL")
xray_recorder.configure(service='backend-flask', dynamic_naming=xray_url)

#X-RAY-------------------
# Calling X-Ray Middleware class
XRayMiddleware(app, xray_recorder)
```

#### 2.4) Setup AWS X-Ray Resources, we created a JSON file (aws/json/xray.json) with parameters for the sampling rule
```json
{
  "SamplingRule": {
      "RuleName": "Cruddur",
      "ResourceARN": "*",
      "Priority": 9000,
      "FixedRate": 0.1,
      "ReservoirSize": 5,
      "ServiceName": "backend-flask",
      "ServiceType": "*",
      "Host": "*",
      "HTTPMethod": "*",
      "URLPath": "*",
      "Version": 1
  }
}
```
#### 2.5) Create an Xray Group on AWS for storing and receiving the data:
```aws
aws xray create-group \
   --group-name "Cruddur" \
   --filter-expression "service(\"backend-flask\")"
```
![image](https://user-images.githubusercontent.com/85003009/222979666-d0cd9f5e-6037-4785-a37c-df297b2fa33e.png)

#### 2.6) Using the JSON file we've created, we generate the rule on AWS X-Ray:
```aws
aws xray create-sampling-rule --cli-input-json file://aws/json/xray.json
```
![image](https://user-images.githubusercontent.com/85003009/222979773-c78f50d6-0ad2-4340-9bf8-545363784062.png)

#### 2.7) Install X-Ray Daemon and add it to docker-compose.yml:

Downloading aws S-Ray daemon:
```bash
 wget https://s3.us-east-2.amazonaws.com/aws-xray-assets.us-east-2/xray-daemon/aws-xray-daemon-3.x.deb
 sudo dpkg -i **.deb
```
Docker-Compose configuration:
```yml
#X-Ray--- 
#Environmental variables
   AWS_XRAY_URL: "*4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}*"
   AWS_XRAY_DAEMON_ADDRESS: "xray-daemon:2000"
#X-Ray--- 
#Daemon configuration
  xray-daemon:
    image: "amazon/aws-xray-daemon"
    environment:
      AWS_ACCESS_KEY_ID: "${AWS_ACCESS_KEY_ID}"
      AWS_SECRET_ACCESS_KEY: "${AWS_SECRET_ACCESS_KEY}"
      AWS_REGION: "ca-central-1"
    command:
      - "xray -o -b xray-daemon:2000"
    ports:
      - 2000:2000/udp
```
#### 2.8) Add @xray_recorder.capture decorator and subsegment

by adding tje decorator to a function or block of code, it creates a new AWS X-Ray segment for that code block, and records timing and metadata information about it. The segment will appear in the AWS X-Ray console as a node in the service map or trace details view, allowing you to visualize and analyze the performance of that code block.

For configuring the decorator, we added the following code to backend-flask/app.py:
```py
#Xray
@xray_recorder.capture('activites_home')
...
#xray
@xray_recorder.capture('activites_users')
...
#xray
@xray_recorder.capture('activites_show')

```

For adding the recoderder subsegment, we added the following lines to the user_activites service:
```py
subsegment = xray_recorder.begin_segment('mockdata')
      dict = {
        "now": now.isoformat(),
        "results-size": len(model['data'])
      }
      subsegment.put_metadata('key',dict,'namespace')
      xray_recorder.end_subsegment()
```

#### 2.9) Send data back to X-Ray API and observe X-Ray traces within the AWS Console

![image](https://user-images.githubusercontent.com/85003009/222981181-1a6dfd1a-4fcf-46fb-a91f-382a160db440.png)

![image](https://user-images.githubusercontent.com/85003009/222981149-ab00c22c-05c0-4ed1-9296-000399a818ba.png)


## 3) CloudWatch Logs

#### 3.1) Add the watchtower sources for provitioning it with python on our backend-flask/requirements.txt file:
```txt
watchtower
```
#### 3.2) Install the watchtower using pip:
```txt
pip install -r requirements.txt
```
#### 3.3) Configuring Logger to Use CloudWatch on Flask backend (app.py)

```py
#CloudWatch--------------
# Importing CloudWatch logs libraries
import watchtower
import logging
from time import strftime

#CloudWatch--------------
# Configuring Logger to Use CloudWatch
LOGGER = logging.getLogger(__name__)
LOGGER.setLevel(logging.DEBUG)
console_handler = logging.StreamHandler()
cw_handler = watchtower.CloudWatchLogHandler(log_group='cruddur')
LOGGER.addHandler(console_handler)
LOGGER.addHandler(cw_handler)
```
#### 3.4) Add environmental variables to docker-compose.yml
```yml
AWS_DEFAULT_REGION: "${AWS_DEFAULT_REGION}"
AWS_ACCESS_KEY_ID: "${AWS_ACCESS_KEY_ID}"
AWS_SECRET_ACCESS_KEY: "${AWS_SECRET_ACCESS_KEY}"
```
#### 3.5) Add the calling to logger function from service page:

on home_activities.py:
```py
import logging
..
class HomeActivities:
  def run(logger):
  logger.info("HomeActivities")
```
on app.py:
```py
@xray_recorder.capture('activites_home')
def data_home():
  data = HomeActivities.run(logger=LOGGER)
```
#### 3.6) Observe the CloudWatch Logs within the AWS Console
![image](https://user-images.githubusercontent.com/85003009/222983372-0f38b1c9-239d-4757-ab80-8f53873ba036.png)


## 4) Rollbar

#### 4.1) Add the rollbar sources for provitioning it with python on our backend-flask/requirements.txt file:
```txt
blinker
rollbar
```
#### 4.2) Install rollbar using pip:
```txt
pip install -r requirements.txt
```
#### 4.3) Configuring error logging Rollbar on Flask backend (app.py)

```py
#Rollbar--------------
# Importing Rollbar logs libraries
import rollbar
import rollbar.contrib.flask
#Rollbar--------------
#Integrate error logging
from flask import got_request_exception
rollbar_access_token = os.getenv('ROLLBAR_ACCESS_TOKEN')
@app.before_first_request
def init_rollbar():
    """init rollbar module"""
    rollbar.init(
        # access token
        rollbar_access_token,
        # environment name
        'production',
        # server root directory, makes tracebacks prettier
        root=os.path.dirname(os.path.realpath(__file__)),
        # flask already sets up logging
        allow_logging_basic_config=False)
    # send exceptions from `app` to rollbar, using flask's signal system.
    got_request_exception.connect(rollbar.contrib.flask.report_exception, app)
```

add and endpoint for testing on app.py:
```py
@app.route('/rollbar/test')
def rollbar_test():
    rollbar.report_message('Hello World!', 'warning')
    return "Hello World!"
```
#### 4.4) Observe how Rollbar handle error trigering:

on home_activites.py we removed a part of the code to see how are errors logged on Rollbar:

![image](https://user-images.githubusercontent.com/85003009/222991763-0462d9cb-293c-4f69-8cb9-3d55755c668f.png)

We can see that errors are being logged:

![image](https://user-images.githubusercontent.com/85003009/222991796-308f8fd8-a0c6-4b0f-a9db-29b9b003eddc.png)

We got a mail notification with the full error as well:

```mail
Project:	FirstProject
Environment:	production
Code Version:	unspecified
Host:	0fb6a1c8d150
Timestamp:	2023-03-05 03:12 pm
A new item has occurred for the first time. View full details of the item at: https://rollbar.com/rodrorivero/FirstProject/items/2/.
View the occurrence that triggered this notification at: https://rollbar.com/rodrorivero/FirstProject/items/2/occurrences/316299134253/

Message
TypeError: The view function for 'data_home' did not return a valid response. The function either returned None or ended without a return statement.

Traceback
Traceback (most recent call last):
  File "/usr/local/lib/python3.10/site-packages/flask/app.py", line 2528, in wsgi_app
    response = self.full_dispatch_request()
  File "/usr/local/lib/python3.10/site-packages/flask/app.py", line 1826, in full_dispatch_request
    return self.finalize_request(rv)
  File "/usr/local/lib/python3.10/site-packages/flask/app.py", line 1845, in finalize_request
    response = self.make_response(rv)
  File "/usr/local/lib/python3.10/site-packages/flask/app.py", line 2137, in make_response
    raise TypeError(
TypeError: The view function for 'data_home' did not return a valid response. The function either returned None or ended without a return statement.
Params
context	/api/activities/home
environment	production
framework	flask
language	python 3.10.10
level	error
notifier.name	pyrollbar
notifier.version	0.16.3
server.argv	["/usr/local/lib/python3.10/site-packages/flask/__main__.py", "run", "--host=0.0.0.0", "--port=4567"]
server.host	0fb6a1c8d150
server.pid	212
server.root	/backend-flask
timestamp	1678057979 - 2023-03-05 03:12:59 pm
uuid	21df88b1-2f22-442f-ade5-17c3757eab42
Replay
Not a replayable item since it doesn't have request params, is a POST, or is a client-side error.
Report grouping issue
If you think there is a problem with grouping this item, you can report it with one click.

https://rollbar.com/rodrorivero/FirstProject/items/2/?utm_campaign=new_item&utm_medium=email&utm_source=rollbar-notification&utm_content=control#reportissue
```


## Summary
- [x] Watched all the instructional videos
- [x] Instrument our backend flask application to use Open Telemetry with Honeycomb
- [x] Run queries to explore traces within Honeycomb.io
- [x] Instrument AWS X-Ray into backend flask application
- [x] Configure and provision X-Ray daemon within docker-compose and send data back to X-Ray API
- [x] Observe X-Ray traces within the AWS Console
- [x] Integrate Rollbar for Error Logging
- [x] Trigger an error an observe an error with Rollbar
- [X] Install WatchTower and write a custom logger to send application log data to - CloudWatch Log group



