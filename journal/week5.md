
```
                                                                                                                                  
   :7YPGGGGGP5?: JGGGGGGGGGPP5J~.  JGGGGG7  ~GGGGG5  5GGGGGGGGP5Y7:    PGGGGGGGGP5Y!.    PGGGGG:  ?GGGGG? .GGGGGGGGGGP5Y7:     
 .5BBBGGBBBBBBB^ JBGGGGGPPGGGGBBG: YBGGGB?  !BGGGGP  PBGGGGBBBBGBBBY.  GGGGGGBBBBGBBBY.  GGGGGB:  JBGGGBJ :BGGGGGPPPGGGBBBJ    
.GBGGGGGJ!^~!?J  JBGGGG5::~GGGGGB? YBGGGB?  ~BGGGGP  PGGGGBY~7PGGGGBG. GGGGGG?^75GGGGBP  GGGGGB:  JBGGGBJ :BGGGGG~.:JBGGGGB.   
^BGGGGB7         JBGGGGGGGGGGGGG5. YBGGGB?  ~BGGGGP  PGGGGB!  .GGGGGB^ GGGGGB:  .GGGGGB^ GGGGGB^  JBGGGBJ :BGGGGGGGGGGGGGG!    
.GBGGGGP?~:^~7?  JBGGGGPYGGGGGB!   !BGGGGP~^5GGGGBJ  PGGGGBJ:!5GGGGBG. GGGGGB7:!5GGGGBG. 5BGGGG5^!GGGGGB~ :BGGGGG55BGGGG5.     
 :5BBGGGBBBBBBB^ JBGGGB? :GGGGGP.   JBBGGGBBGGGBB5.  PGGGGGGBBBGBBB5:  GGGGGGBBBBGBBB5:  .5BBGGGBBGGGBB?  :BGGGGG. JBGGGG7     
   ^?5GGGGGGGPJ: JGGGGG?  ^GGGGGP.   :?5GGGGGGPJ^    5GGGGGGGGGPY?:    PGGGGGGGGGPY7:      ~Y5GGGGGP5?:   .GGGGGG.  5GGGGG7       
                                                                                                                                  
```  
# Week 5 — DynamoDB and Serverless Caching

## 1) Enabling DynamoDB on AWS
#### 1.1) Install python libraries for communicating with AWS DynamoDB

```txt
boto3
```

```bash
pip install -r requirements.txt
```

#### 1.2) Create the libraries for connecting to dynamo DB:

  a) drop:

  ```bash
  #! /usr/bin/bash
  set -e # stop if it fails at any point
  if [ -z "$1" ]; then
    echo "No TABLE_NAME argument supplied eg ./bin/ddb/drop cruddur-messages prod "
    exit 1
  fi
  TABLE_NAME=$1
  if [ "$2" = "prod" ]; then
    ENDPOINT_URL=""
  else
    ENDPOINT_URL="--endpoint-url=http://localhost:8000"
  fi
  echo "deleting table: $TABLE_NAME"
  aws dynamodb delete-table $ENDPOINT_URL \
    --table-name $TABLE_NAME
  ``` 

  b) list-tables:

  ```bash
  #! /usr/bin/bash
  set -e # stop if it fails at any point

  if [ "$1" = "prod" ]; then
    ENDPOINT_URL=""
  else
    ENDPOINT_URL="--endpoint-url=http://localhost:8000"
  fi

  aws dynamodb list-tables $ENDPOINT_URL \
  --query TableNames \
  --output table
  ``` 

  c) scan:

  ```bash
  #!/usr/bin/env python3
  import boto3
  attrs = {
    'endpoint_url': 'http://localhost:8000'
  }
  ddb = boto3.resource('dynamodb',**attrs)
  table_name = 'cruddur-messages'
  table = ddb.Table(table_name)
  response = table.scan()
  items = response['Items']
  for item in items:
    print(item)
  ``` 

  d) schema-load:

  ```bash
  #!/usr/bin/env python3
  import boto3
  import sys
  attrs = {
    'endpoint_url': 'http://localhost:8000'
  }
  if len(sys.argv) == 2:
    if "prod" in sys.argv[1]:
      attrs = {}
  ddb = boto3.client('dynamodb',**attrs)
  table_name = 'cruddur-messages'
  response = ddb.create_table(
    TableName=table_name,
    AttributeDefinitions=[
      {
        'AttributeName': 'pk',
        'AttributeType': 'S'
      },
      {
        'AttributeName': 'sk',
        'AttributeType': 'S'
      },
    ],
    KeySchema=[
      {
        'AttributeName': 'pk',
        'KeyType': 'HASH'
      },
      {
        'AttributeName': 'sk',
        'KeyType': 'RANGE'
      },
    ],
    #GlobalSecondaryIndexes=[
    #],
    BillingMode='PROVISIONED',
    ProvisionedThroughput={
        'ReadCapacityUnits': 5,
        'WriteCapacityUnits': 5
    }
  )
  print(response)
  ``` 

  e) seed:

  ```bash
  #!/usr/bin/env python3

  import boto3
  import os
  import sys
  from datetime import datetime, timedelta, timezone
  import uuid

  current_path = os.path.dirname(os.path.abspath(__file__))
  parent_path = os.path.abspath(os.path.join(current_path, '..', '..'))
  sys.path.append(parent_path)
  from lib.db import db

  attrs = {
    'endpoint_url': 'http://localhost:8000'
  }
  # unset endpoint url for use with production database
  if len(sys.argv) == 2:
    if "prod" in sys.argv[1]:
      attrs = {}
  ddb = boto3.client('dynamodb',**attrs)

  def get_user_uuids():
    sql = """
      SELECT 
        users.uuid,
        users.display_name,
        users.handle
      FROM users
      WHERE
        users.handle IN(
          %(my_handle)s,
          %(other_handle)s
          )
    """
    users = db.query_array_json(sql,{
      'my_handle':  'carlos_r',
      'other_handle': 'rodrigorivero'
    })
    my_user    = next((item for item in users if item["handle"] == 'carlos_r'), None)
    other_user = next((item for item in users if item["handle"] == 'rodrigorivero'), None)
    results = {
      'my_user': my_user,
      'other_user': other_user
    }
    print('get_user_uuids')
    print(results)
    return results
  def create_message_group(client,message_group_uuid, my_user_uuid, last_message_at=None, message=None, other_user_uuid=None, other_user_display_name=None,           other_user_handle=None):
    table_name = 'cruddur-messages'
    record = {
      'pk':   {'S': f"GRP#{my_user_uuid}"},
      'sk':   {'S': last_message_at},
      'message_group_uuid': {'S': message_group_uuid},
      'message':  {'S': message},
      'user_uuid': {'S': other_user_uuid},
      'user_display_name': {'S': other_user_display_name},
      'user_handle': {'S': other_user_handle}
    }

    response = client.put_item(
      TableName=table_name,
      Item=record
    )
    print(response)

  def create_message(client,message_group_uuid, created_at, message, my_user_uuid, my_user_display_name, my_user_handle):
    table_name = 'cruddur-messages'
    record = {
      'pk':   {'S': f"MSG#{message_group_uuid}"},
      'sk':   {'S': created_at },
      'message_uuid': { 'S': str(uuid.uuid4()) },
      'message': {'S': message},
      'user_uuid': {'S': my_user_uuid},
      'user_display_name': {'S': my_user_display_name},
      'user_handle': {'S': my_user_handle}
    }
    # insert the record into the table
    response = client.put_item(
      TableName=table_name,
      Item=record
    )
    # print the response
    print(response)

  message_group_uuid = "5ae290ed-55d1-47a0-bc6d-fe2bc2700399" 
  now = datetime.now(timezone.utc).astimezone()
  users = get_user_uuids()

  create_message_group(
    client=ddb,
    message_group_uuid=message_group_uuid,
    my_user_uuid=users['my_user']['uuid'],
    other_user_uuid=users['other_user']['uuid'],
    other_user_handle=users['other_user']['handle'],
    other_user_display_name=users['other_user']['display_name'],
    last_message_at=now.isoformat(),
    message="this is a filler message"
  )

  create_message_group(
    client=ddb,
    message_group_uuid=message_group_uuid,
    my_user_uuid=users['other_user']['uuid'],
    other_user_uuid=users['my_user']['uuid'],
    other_user_handle=users['my_user']['handle'],
    other_user_display_name=users['my_user']['display_name'],
    last_message_at=now.isoformat(),
    message="this is a filler message"
  )

  conversation = """
  Person 1: Have you ever watched Babylon 5? It's one of my favorite TV shows!
  Person 2: Yes, I have! I love it too. What's your favorite season?
  Person 1: I think my favorite season has to be season 3. So many great episodes, like "Severed Dreams" and "War Without End."
  Person 2: Yeah, season 3 was amazing! I also loved season 4, especially with the Shadow War heating up and the introduction of the White Star.
  Person 1: Agreed, season 4 was really great as well. I was so glad they got to wrap up the storylines with the Shadows and the Vorlons in that season.
  Person 2: Definitely. What about your favorite character? Mine is probably Londo Mollari.
  Person 1: Londo is great! My favorite character is probably G'Kar. I loved his character development throughout the series.
  Person 2: G'Kar was definitely a standout character. I also really liked Delenn's character arc and how she grew throughout the series.
  ....
  """


  lines = conversation.lstrip('\n').rstrip('\n').split('\n')
  for i in range(len(lines)):
    if lines[i].startswith('Person 1: '):
      key = 'my_user'
      message = lines[i].replace('Person 1: ', '')
    elif lines[i].startswith('Person 2: '):
      key = 'other_user'
      message = lines[i].replace('Person 2: ', '')
    else:
      print(lines[i])
      raise 'invalid line'

    created_at = (now + timedelta(minutes=i)).isoformat()
    create_message(
      client=ddb,
      message_group_uuid=message_group_uuid,
      created_at=created_at,
      message=message,
      my_user_uuid=users[key]['uuid'],
      my_user_display_name=users[key]['display_name'],
      my_user_handle=users[key]['handle']
    )
  ``` 

#### 1.2) Creation of patterns for using the queries on DynamoDB

  a) get-conversation:

  ```bash
  #!/usr/bin/env python3
  import boto3
  import sys
  import json
  import datetime

  attrs = {
    'endpoint_url': 'http://localhost:8000'
  }
  if len(sys.argv) == 2:
    if "prod" in sys.argv[1]:
      attrs = {}
  dynamodb = boto3.client('dynamodb',**attrs)
  table_name = 'cruddur-messages'
  message_group_uuid = "5ae290ed-55d1-47a0-bc6d-fe2bc2700399"
  # define the query parameters
  current_year = datetime.datetime.now().year
  query_params = {
    'TableName': table_name,
    'ScanIndexForward': False,
    'Limit': 20,
    'ReturnConsumedCapacity': 'TOTAL',
    'KeyConditionExpression': 'pk = :pk AND begins_with(sk,:year)',
    #'KeyConditionExpression': 'pk = :pk AND sk BETWEEN :start_date AND :end_date',
    'ExpressionAttributeValues': {
      ':year': {'S': '2023'},
      #":start_date": { "S": "2023-03-01T00:00:00.000000+00:00" },
      #":end_date": { "S": "2023-03-19T23:59:59.999999+00:00" },
      ':pk': {'S': f"MSG#{message_group_uuid}"}
    }
  }
  # query the table
  response = dynamodb.query(**query_params)
  # print the items returned by the query
  print(json.dumps(response, sort_keys=True, indent=2))
  # print the consumed capacity
  print(json.dumps(response['ConsumedCapacity'], sort_keys=True, indent=2))
  items = response['Items']
  items.reverse()
  for item in items:
    sender_handle = item['user_handle']['S']
    message       = item['message']['S']
    timestamp     = item['sk']['S']
    dt_object = datetime.datetime.strptime(timestamp, '%Y-%m-%dT%H:%M:%S.%f%z')
    formatted_datetime = dt_object.strftime('%Y-%m-%d %I:%M %p')
    print(f'{sender_handle: <12}{formatted_datetime: <22}{message[:40]}...')
  ``` 


  b) list-conversation:
  ```bash
  #!/usr/bin/env python3

  import boto3
  import sys
  import json
  import os
  import datetime
  current_path = os.path.dirname(os.path.abspath(__file__))
  parent_path = os.path.abspath(os.path.join(current_path, '..', '..', '..'))
  sys.path.append(parent_path)
  from lib.db import db
  attrs = {
    'endpoint_url': 'http://localhost:8000'
  }
  if len(sys.argv) == 2:
    if "prod" in sys.argv[1]:
      attrs = {}
  dynamodb = boto3.client('dynamodb',**attrs)
  table_name = 'cruddur-messages'
  def get_my_user_uuid():
    sql = """
      SELECT 
        users.uuid
      FROM users
      WHERE
        users.handle =%(handle)s
    """
    uuid = db.query_value(sql,{
      'handle':  'carlos_r'
    })
    return uuid
  my_user_uuid = get_my_user_uuid()
  print(f"my-uuid: {my_user_uuid}")
  current_year = datetime.datetime.now().year
  # define the query parameters
  query_params = {
    'TableName': table_name,
        'KeyConditionExpression': 'pk = :pk AND begins_with(sk,:year)',
    'ScanIndexForward': False,
    'ExpressionAttributeValues': {
      ':year': {'S': str(current_year) },
      ':pk': {'S': f"GRP#{my_user_uuid}"}
    },
    'ReturnConsumedCapacity': 'TOTAL'
  }
  # query the table
  response = dynamodb.query(**query_params)
  # print the items returned by the query
  print(json.dumps(response, sort_keys=True, indent=2))
  ``` 

  c) update db.py
  ```py
    def query_value(self,sql,params={}):
      self.print_sql('value',sql,params)
      with self.pool.connection() as conn:
        with conn.cursor() as cur:
          cur.execute(sql,params)
          json = cur.fetchone()
          return json[0]
  ``` 

#### 1.3) Creation of Dynamo DB Lybrary in python:

a) dbd.py library:

  ```py
    import boto3
    import sys
    from datetime import datetime, timedelta, timezone
    import uuid
    import os
    import botocore.exceptions

    class Ddb:
      def client():
        endpoint_url = os.getenv("AWS_ENDPOINT_URL")
        if endpoint_url:
          attrs = { 'endpoint_url': endpoint_url }
        else:
          attrs = {}
        dynamodb = boto3.client('dynamodb',**attrs)
        return dynamodb
      def list_message_groups(client,my_user_uuid):
        year = str(datetime.now().year)
        table_name = 'cruddur-messages'
        query_params = {
          'TableName': table_name,
          'KeyConditionExpression': 'pk = :pk AND begins_with(sk,:year)',
          'ScanIndexForward': False,
          'Limit': 20,
          'ExpressionAttributeValues': {
            ':year': {'S': year },
            ':pk': {'S': f"GRP#{my_user_uuid}"}
          }
        }
        print('query-params:',query_params)
        print(query_params)
        # query the table
        response = client.query(**query_params)
        items = response['Items']


        results = []
        for item in items:
          last_sent_at = item['sk']['S']
          results.append({
            'uuid': item['message_group_uuid']['S'],
            'display_name': item['user_display_name']['S'],
            'handle': item['user_handle']['S'],
            'message': item['message']['S'],
            'created_at': last_sent_at
          })
        return results
      def list_messages(client,message_group_uuid):
        year = str(datetime.now().year)
        table_name = 'cruddur-messages'
        query_params = {
          'TableName': table_name,
          'KeyConditionExpression': 'pk = :pk AND begins_with(sk,:year)',
          'ScanIndexForward': False,
          'Limit': 20,
          'ExpressionAttributeValues': {
            ':year': {'S': year },
            ':pk': {'S': f"MSG#{message_group_uuid}"}
          }
        }

        response = client.query(**query_params)
        items = response['Items']
        items.reverse()
        results = []
        for item in items:
          created_at = item['sk']['S']
          results.append({
            'uuid': item['message_uuid']['S'],
            'display_name': item['user_display_name']['S'],
            'handle': item['user_handle']['S'],
            'message': item['message']['S'],
            'created_at': created_at
          })
        return results
      def create_message(client,message_group_uuid, message, my_user_uuid, my_user_display_name, my_user_handle):
        now = datetime.now(timezone.utc).astimezone().isoformat()
        created_at = now
        message_uuid = str(uuid.uuid4())

        record = {
          'pk':   {'S': f"MSG#{message_group_uuid}"},
          'sk':   {'S': created_at },
          'message': {'S': message},
          'message_uuid': {'S': message_uuid},
          'user_uuid': {'S': my_user_uuid},
          'user_display_name': {'S': my_user_display_name},
          'user_handle': {'S': my_user_handle}
        }
        # insert the record into the table
        table_name = 'cruddur-messages'
        response = client.put_item(
          TableName=table_name,
          Item=record
        )
        # print the response
        print(response)
        return {
          'message_group_uuid': message_group_uuid,
          'uuid': my_user_uuid,
          'display_name': my_user_display_name,
          'handle':  my_user_handle,
          'message': message,
          'created_at': created_at
        }
      def create_message_group(client, message,my_user_uuid, my_user_display_name, my_user_handle, other_user_uuid, other_user_display_name, other_user_handle):
        print('== create_message_group.1')
        table_name = 'cruddur-messages'

        message_group_uuid = str(uuid.uuid4())
        message_uuid = str(uuid.uuid4())
        now = datetime.now(timezone.utc).astimezone().isoformat()
        last_message_at = now
        created_at = now
        print('== create_message_group.2')

        my_message_group = {
          'pk': {'S': f"GRP#{my_user_uuid}"},
          'sk': {'S': last_message_at},
          'message_group_uuid': {'S': message_group_uuid},
          'message': {'S': message},
          'user_uuid': {'S': other_user_uuid},
          'user_display_name': {'S': other_user_display_name},
          'user_handle':  {'S': other_user_handle}
        }

        print('== create_message_group.3')
        other_message_group = {
          'pk': {'S': f"GRP#{other_user_uuid}"},
          'sk': {'S': last_message_at},
          'message_group_uuid': {'S': message_group_uuid},
          'message': {'S': message},
          'user_uuid': {'S': my_user_uuid},
          'user_display_name': {'S': my_user_display_name},
          'user_handle':  {'S': my_user_handle}
        }

        print('== create_message_group.4')
        message = {
          'pk':   {'S': f"MSG#{message_group_uuid}"},
          'sk':   {'S': created_at },
          'message': {'S': message},
          'message_uuid': {'S': message_uuid},
          'user_uuid': {'S': my_user_uuid},
          'user_display_name': {'S': my_user_display_name},
          'user_handle': {'S': my_user_handle}
        }

        items = {
          table_name: [
            {'PutRequest': {'Item': my_message_group}},
            {'PutRequest': {'Item': other_message_group}},
            {'PutRequest': {'Item': message}}
          ]
        }

        try:
          print('== create_message_group.try')
          # Begin the transaction
          response = client.batch_write_item(RequestItems=items)
          return {
            'message_group_uuid': message_group_uuid
          }
        except botocore.exceptions.ClientError as e:
          print('== create_message_group.error')
          print(e)
  ``` 
### 2) Configuration of Conversations:
#### 2.1) Creation of posgres libraries:
 
 a) Query for creating messages: backend-flask/db/sql/users/create_message_users.sql
  
   ```sql
    SELECT 
    users.uuid,
    users.display_name,
    users.handle,
    CASE users.cognito_user_id = %(cognito_user_id)s
    WHEN TRUE THEN
      'sender'
    WHEN FALSE THEN
      'recv'
    ELSE
      'other'
    END as kind
    FROM public.users
    WHERE
      users.cognito_user_id = %(cognito_user_id)s
      OR 
      users.handle = %(user_receiver_handle)s
   ``` 
b) Query for getting the users handle:  backend-flask/db/sql/users/short.sql

   ```sql
     SELECT
      users.uuid,
      users.handle,
      users.display_name
    FROM public.users
    WHERE 
      users.handle = %(handle)s
   ``` 
c) Query for getting the UUID from cognito: backend-flask/db/sql/users/uuid_from_cognito_user_id.sql

   ```sql
    SELECT
      users.uuid
    FROM public.users
    WHERE 
      users.cognito_user_id = %(cognito_user_id)s
    LIMIT 1
   ``` 
    
d) Python module for listing the cognito users: backend-flask/bin/cognito/list-users
   
   ```py
    import boto3
    import os
    import json

    userpool_id = os.getenv("AWS_COGNITO_USER_POOL_ID")
    client = boto3.client('cognito-idp')
    params = {
      'UserPoolId': userpool_id,
      'AttributesToGet': [
          'preferred_username',
          'sub'
      ]
    }
    response = client.list_users(**params)
    users = response['Users']

    print(json.dumps(users, sort_keys=True, indent=2, default=str))

    dict_users = {}
    for user in users:
      attrs = user['Attributes']
      sub    = next((a for a in attrs if a["Name"] == 'sub'), None)
      handle = next((a for a in attrs if a["Name"] == 'preferred_username'), None)
      dict_users[handle['Value']] = sub['Value']

    print(json.dumps(dict_users, sort_keys=True, indent=2, default=str))
   ```
#### 3) Front End Implementation of conversations:
#### 3.1) Implementing meesage group page

a) create js page: frontend-react-js/src/pages/MessageGroupNewPage.js

  ```js
     import './MessageGroupPage.css';
    import React from "react";
    import { useParams } from 'react-router-dom';

    import DesktopNavigation  from '../components/DesktopNavigation';
    import MessageGroupFeed from '../components/MessageGroupFeed';
    import MessagesFeed from '../components/MessageFeed';
    import MessagesForm from '../components/MessageForm';
    import checkAuth from '../lib/CheckAuth';

    export default function MessageGroupPage() {
      const [otherUser, setOtherUser] = React.useState([]);
      const [messageGroups, setMessageGroups] = React.useState([]);
      const [messages, setMessages] = React.useState([]);
      const [popped, setPopped] = React.useState([]);
      const [user, setUser] = React.useState(null);
      const dataFetchedRef = React.useRef(false);
      const params = useParams();

      const loadUserShortData = async () => {
        try {
          const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/users/@${params.handle}/short`
          const res = await fetch(backend_url, {
            method: "GET"
          });
          let resJson = await res.json();
          if (res.status === 200) {
            console.log('other user:',resJson)
            setOtherUser(resJson)
          } else {
            console.log(res)
          }
        } catch (err) {
          console.log(err);
        }
      };  

      const loadMessageGroupsData = async () => {
        try {
          const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/message_groups`
          const res = await fetch(backend_url, {
            headers: {
              Authorization: `Bearer ${localStorage.getItem("access_token")}`
            },
            method: "GET"
          });
          let resJson = await res.json();
          if (res.status === 200) {
            setMessageGroups(resJson)
          } else {
            console.log(res)
          }
        } catch (err) {
          console.log(err);
        }
      };  

      React.useEffect(()=>{
        //prevents double call
        if (dataFetchedRef.current) return;
        dataFetchedRef.current = true;

        loadMessageGroupsData();
        loadUserShortData();
        checkAuth(setUser);
      }, [])
      return (
        <article>
          <DesktopNavigation user={user} active={'home'} setPopped={setPopped} />
          <section className='message_groups'>
            <MessageGroupFeed otherUser={otherUser} message_groups={messageGroups} />
          </section>
          <div className='content messages'>
            <MessagesFeed messages={messages} />
            <MessagesForm setMessages={setMessages} />
          </div>
        </article>
      );
    }
  ``` 
b) Create module for verifying cognito id and handle frontend-react-js/src/lib/CheckAuth.js:
  ```js
  import { Auth } from 'aws-amplify';

  const checkAuth = async (setUser) => {
    Auth.currentAuthenticatedUser({
      // Optional, By default is false. 
      // If set to true, this call will send a 
      // request to Cognito to get the latest user data
      bypassCache: false 
    })
    .then((user) => {
      console.log('user',user);
      return Auth.currentAuthenticatedUser()
    }).then((cognito_user) => {
        setUser({
          display_name: cognito_user.attributes.name,
          handle: cognito_user.attributes.preferred_username
        })
    })
    .catch((err) => console.log(err));
  };
  ```
 

c) create library for messaging stream: aws/lambdas/cruddur-messaging-stream.py
  ```py
  import json
  import boto3
  from boto3.dynamodb.conditions import Key, Attr

  dynamodb = boto3.resource(
   'dynamodb',
   region_name='ca-central-1',
   endpoint_url="http://dynamodb.ca-central-1.amazonaws.com"
  )

  def lambda_handler(event, context):
    print('event-data',event)

    eventName = event['Records'][0]['eventName']
    if (eventName == 'REMOVE'):
      print("skip REMOVE event")
      return
    pk = event['Records'][0]['dynamodb']['Keys']['pk']['S']
    sk = event['Records'][0]['dynamodb']['Keys']['sk']['S']
    if pk.startswith('MSG#'):
      group_uuid = pk.replace("MSG#","")
      message = event['Records'][0]['dynamodb']['NewImage']['message']['S']
      print("GRUP ===>",group_uuid,message)

      table_name = 'cruddur-messages'
      index_name = 'message-group-sk-index'
      table = dynamodb.Table(table_name)
      data = table.query(
        IndexName=index_name,
        KeyConditionExpression=Key('message_group_uuid').eq(group_uuid)
      )
      print("RESP ===>",data['Items'])

      # recreate the message group rows with new SK value
      for i in data['Items']:
        delete_item = table.delete_item(Key={'pk': i['pk'], 'sk': i['sk']})
        print("DELETE ===>",delete_item)

        response = table.put_item(
          Item={
            'pk': i['pk'],
            'sk': sk,
            'message_group_uuid':i['message_group_uuid'],
            'message':message,
            'user_display_name': i['user_display_name'],
            'user_handle': i['user_handle'],
            'user_uuid': i['user_uuid']
          }
        )
        print("CREATE ===>",response)
  ``` 
d) create json policy on AWS for allowing inserts on AWS:
  ```bash
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem",
                "dynamodb:DeleteItem",
                "dynamodb:Query"
            ],
            "Resource": [
                "arn:aws:dynamodb:ca-central-1:387543059434:table/cruddur-messages",
                "arn:aws:dynamodb:ca-central-1:387543059434:table/cruddur-messages/index/message-group-sk-index"
            ]
        }
    ]
  }
  ``` 

e) create js for new item on messages page: frontend-react-js/src/components/MessageGroupNewItem.js
  ```bash
  import './MessageGroupItem.css';
  import { Link } from "react-router-dom";

  export default function MessageGroupNewItem(props) {
    return (

      <Link className='message_group_item active' to={`/messages/new/`+props.user.handle}>
        <div className='message_group_avatar'></div>
        <div className='message_content'>
          <div classsName='message_group_meta'>
            <div className='message_group_identity'>
              <div className='display_name'>{props.user.display_name}</div>
              <div className="handle">@{props.user.handle}</div>
            </div>{/* activity_identity */}
          </div>{/* message_meta */}
        </div>{/* message_content */}
      </Link>
    );
  }
  ``` 
 
![2023-04-04 21_46_07-Cruddur](https://user-images.githubusercontent.com/85003009/233800894-9f13e5ba-6d46-4a44-b017-32e54a671628.png)


Create the libraries for accessing data patterns:

create a dynamo db table:

![image](https://user-images.githubusercontent.com/85003009/232259852-3bcd121e-f342-4f56-a2b0-cc843d5a0d12.png)


create a lambda for messaging stream:

![image](https://user-images.githubusercontent.com/85003009/232259811-b95faa8f-a927-4d9b-ba2e-7cbaa9f694b9.png)



## Summary
- [x] Data Modelling a Direct Messaging System using Single Table Design
- [x] Implementing DynamoDB query using Single Table Design
- [x] Provisioning DynamoDB tables with Provisioned Capacity
- [x] Utilizing a Global Secondary Index (GSI) with DynamoDB
- [x] Rapid data modelling and implementation of DynamoDB with DynamoDB Local
- [x] Writing utility scripts to easily setup and teardown and debug DynamoDB data

