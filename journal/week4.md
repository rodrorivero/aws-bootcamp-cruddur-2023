```
                                                                                                                                  
   :7YPGGGGGP5?: JGGGGGGGGGPP5J~.  JGGGGG7  ~GGGGG5  5GGGGGGGGP5Y7:    PGGGGGGGGP5Y!.    PGGGGG:  ?GGGGG? .GGGGGGGGGGP5Y7:     
 .5BBBGGBBBBBBB^ JBGGGGGPPGGGGBBG: YBGGGB?  !BGGGGP  PBGGGGBBBBGBBBY.  GGGGGGBBBBGBBBY.  GGGGGB:  JBGGGBJ :BGGGGGPPPGGGBBBJ    
.GBGGGGGJ!^~!?J  JBGGGG5::~GGGGGB? YBGGGB?  ~BGGGGP  PGGGGBY~7PGGGGBG. GGGGGG?^75GGGGBP  GGGGGB:  JBGGGBJ :BGGGGG~.:JBGGGGB.   
^BGGGGB7         JBGGGGGGGGGGGGG5. YBGGGB?  ~BGGGGP  PGGGGB!  .GGGGGB^ GGGGGB:  .GGGGGB^ GGGGGB^  JBGGGBJ :BGGGGGGGGGGGGGG!    
.GBGGGGP?~:^~7?  JBGGGGPYGGGGGB!   !BGGGGP~^5GGGGBJ  PGGGGBJ:!5GGGGBG. GGGGGB7:!5GGGGBG. 5BGGGG5^!GGGGGB~ :BGGGGG55BGGGG5.     
 :5BBGGGBBBBBBB^ JBGGGB? :GGGGGP.   JBBGGGBBGGGBB5.  PGGGGGGBBBGBBB5:  GGGGGGBBBBGBBB5:  .5BBGGGBBGGGBB?  :BGGGGG. JBGGGG7     
   ^?5GGGGGGGPJ: JGGGGG?  ^GGGGGP.   :?5GGGGGGPJ^    5GGGGGGGGGPY?:    PGGGGGGGGGPY7:      ~Y5GGGGGP5?:   .GGGGGG.  5GGGGG7       
                                                                                                                                  
```  
# Week 4 — Postgres and RDS

## 1) Postgres

create a local database called cruddr:

```psql
CREATE database cruddur;
```
create a sql file called schema.sql for executing the plsql queries:

```psql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```
create a connection string to database cruddr on Posgres and store it as environmental variable:

```bash
gp env CONNECTION_URL="postgresql://postgres:*****@127.0.0.1:5433/cruddur"
```

#### 1.1) Create the binaries for postres

In order to make easier the handling of creation, connection and seeding, we created the following files:
Script for connect to the database,  db-connect:

```bash
#! /usr/bin/bash
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-connect"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"
psql $CONNECTION_URL
```
Script for calling the database's mock data creation, db-seed:

```bash
#! /usr/bin/bash
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-seed-load"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

seed_path=$(realpath .)/db/seed.sql

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  echo "Running in development mode"
  URL=$CONNECTION_URL
fi

psql $URL cruddur < $seed_path
```
Script for create the database's schema, db-schema-load:

```bash
#! /usr/bin/bash
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-schema-load"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"
schema_path=$(realpath .)/db/schema.sql
if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  echo "Running in development mode"
  URL=$CONNECTION_URL
fi
psql $URL cruddur < $schema_path
```
Script for droping the database db-drop:

>Here I had to add some code to kill all sesions because sometimes it gave me some errors:

```bash
#! /usr/bin/bash
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-drop"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")

psql $NO_DB_CONNECTION_URL -c "
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = 'cruddur';"

psql $NO_DB_CONNECTION_URL -c "DROP database cruddur;"
```
Script for creating the database, db-create:

```bash
#! /usr/bin/bash
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-create"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"
NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "CREATE database cruddur;"
```
#### 1.2) create the PSQL queries for Postgres:

In order to create the tables, we configure schema.sql:

```psql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.activities;
CREATE TABLE public.users (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  display_name text,
  handle text,
  cognito_user_id text,
  created_at TIMESTAMP default current_timestamp NOT NULL
);

CREATE TABLE public.activities (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_uuid UUID NOT NULL,
  message text NOT NULL,
  replies_count integer DEFAULT 0,
  reposts_count integer DEFAULT 0,
  likes_count integer DEFAULT 0,
  reply_to_activity_uuid integer,
  expires_at TIMESTAMP,
  created_at TIMESTAMP default current_timestamp NOT NULL
);
```

for automatic insertion of mock data we create the see.sql file:

```psql
-- this file was manually created
INSERT INTO public.users (display_name, handle, cognito_user_id)
VALUES
  ('Andrew Brown', 'andrewbrown' ,'MOCK'),
  ('Andrew Bayko', 'bayko' ,'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'andrewbrown' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )
```

then we test the connection and verify the data creation:

![image](https://user-images.githubusercontent.com/85003009/227758052-36fced7d-aa33-4b5e-ac17-b4e44c585fb8.png)


#### 1.3) Install Psycopg - PostgreSQL database adapter for python

In order to configure the communication between the backend and the database we add the postgress driver libraries to requirements.txt

```txt
psycopg[binary]
psycopg[pool]
```

```bash
pip install -r requirements.txt
```
Then we make sure to pass the EV for connection to the database through docker compose:

```yml
version: "3.8"
services:
  backend-flask:
    environment:
      CONNECTION_URL: "${CONNECTION_URL}"
```

On home_activites.py we import the just created library:

```py
from lib.db import pool
```

Create the script to connect to dabase, db-connect:

```bash
#! /usr/bin/bash
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-connect"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  echo "Running in development mode"
  URL=$CONNECTION_URL
fi

psql $URL
```


Then create a security group, to allow the communication between Lambda and Postgres, and for making the rule dynamic we export the ENV

```bash
export DB_SG_ID="sg-0f746e2d320a853c8"
gp env DB_SG_ID="sg-0f746e2d320a853c8"
export DB_SG_RULE_ID="sgr-093953b3b829d9584"
gp env DB_SG_RULE_ID="sgr-093953b3b829d9584"
```

Create the dynamic rule for updating the security group, rds-update-sg-rule

```bash
#! /usr/bin/bash
GREEN='\033[0;32m'
NO_COLOR='\033[0m'
LABEL="rds-update-sg-rule"
printf "${GREEN}== ${LABEL}${NO_COLOR}\n"

aws ec2 modify-security-group-rules \
    --group-id $DB_SG_ID \
    --security-group-rules "SecurityGroupRuleId=$DB_SG_RULE_ID,SecurityGroupRule={Description=GITPOD,IpProtocol=tcp,FromPort=5432,ToPort=5432,CidrIpv4=${GITPOD_IP}/32}"
```
Program it for automatic execution on gitpod.yml

```yml
  command:
    export GITPOD_IP=$(curl ifconfig.me)
    source "$THEIA_WORKSPACE_ROOT/backend-flask/rds-update-sg-rule"
``` 
    

#### 1.4) Cognito Post Confirmation Lambda

We create a Lambda function for storing the authentication data from cognito into our postgres database.

```py
import json
import psycopg2
import os

def lambda_handler(event, context):
    user = event['request']['userAttributes']
    user_display_name          = user['name']
    user_email                 = user['email']
    user_handle    = user['preferred_username']    
    user_cognito_id            = user['sub']
    print('userAttributes')
    print(user)
    try:
        sql=f"""
        INSERT INTO users (
        display_name, 
        email,
        handle,
        cognito_user_id
        ) 
        VALUES(
       '{user_display_name}', 
        '{user_email}', 
        '{user_handle}',
        '{user_cognito_id}');
        """
        conn = psycopg2.connect(os.getenv('CONNECTION_URL'))
        cur = conn.cursor()        
        cur.execute(sql)
        conn.commit() 

    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
        
    finally:
        if conn is not None:
            cur.close()
            conn.close()
            print('Database connection closed.')

    return event
```

## 2) Activities creation

Create a library for activity creations, this will store our crudds on the database and associate them with the user:

`create_activity.py`
```py
import uuid
from datetime import datetime, timedelta, timezone
import lib.db import db
class CreateActivity:
  def run(message, user_handle, ttl):
    model = {
      'errors': None,
      'data': None
    }

    now = datetime.now(timezone.utc).astimezone()

    if (ttl == '30-days'):
      ttl_offset = timedelta(days=30) 
    elif (ttl == '7-days'):
      ttl_offset = timedelta(days=7) 
    elif (ttl == '3-days'):
      ttl_offset = timedelta(days=3) 
    elif (ttl == '1-day'):
      ttl_offset = timedelta(days=1) 
    elif (ttl == '12-hours'):
      ttl_offset = timedelta(hours=12) 
    elif (ttl == '3-hours'):
      ttl_offset = timedelta(hours=3) 
    elif (ttl == '1-hour'):
      ttl_offset = timedelta(hours=1) 
    else:
      model['errors'] = ['ttl_blank']

    if user_handle == None or len(user_handle) < 1:
      model['errors'] = ['user_handle_blank']

    if message == None or len(message) < 1:
      model['errors'] = ['message_blank'] 
    elif len(message) > 280:
      model['errors'] = ['message_exceed_max_chars'] 

    if model['errors']:
      model['data'] = {
        'handle':  user_handle,
        'message': message
      }   
    else:
      model['data'] = {
        'uuid': uuid.uuid4(),
        'display_name': 'Andrew Brown',
        'handle':  user_handle,
        'message': message,
        'created_at': now.isoformat(),
        'expires_at': (now + ttl_offset).isoformat()
      }
    return model

  def create_activity(handle, message, expires_at):
    sql = db.template('activities','create')
    uuid = db.query_commit(sql,{
      'handle': handle,
      'message': message,
      'expires_at': expires_at
    })
    return uuid
  
  def query_object_activity(uuid):
    sql = db.template('activities','object')
    return db.query_object_json(sql,{
      'uuid': uuid
    })
```

Then create the queries for managing the activities:

`create.sql`
```sql
INSERT INTO public.activities (
  user_uuid,
  message,
  expires_at
)
VALUES (
  (SELECT uuid 
    FROM public.users 
    WHERE users.handle = %(handle)s
    LIMIT 1
  ),
  %(message)s,
  %(expires_at)s
) RETURNING uuid;
```

`home.sql`
```sql
SELECT
  activities.uuid,
  users.display_name,
  users.handle,
  activities.message,
  activities.replies_count,
  activities.reposts_count,
  activities.likes_count,
  activities.reply_to_activity_uuid,
  activities.expires_at,
  activities.created_at
FROM public.activities
LEFT JOIN public.users ON users.uuid = activities.user_uuid
ORDER BY activities.created_at DESC
```

`object.sql`
```sql
SELECT
  activities.uuid,
  users.display_name,
  users.handle,
  activities.message,
  activities.created_at,
  activities.expires_at
FROM public.activities
INNER JOIN public.users ON users.uuid = activities.user_uuid 
WHERE 
  activities.uuid = %(uuid)s
```

Update the database library for executing the queries

`db.py`
```py
from psycopg_pool import ConnectionPool
import os
import re
import sys
from flask import current_app as app

class Db:
  def __init__(self):
    self.init_pool()

  def template(self,*args):
    pathing = list((app.root_path,'db','sql',) + args)
    pathing[-1] = pathing[-1] + ".sql"

    template_path = os.path.join(*pathing)

    green = '\033[92m'
    no_color = '\033[0m'
    print("\n")
    print(f'{green} Load SQL Template: {template_path} {no_color}')

    with open(template_path, 'r') as f:
      template_content = f.read()
    return template_content

  def init_pool(self):
    connection_url = os.getenv("CONNECTION_URL")
    self.pool = ConnectionPool(connection_url)
  # we want to commit data such as an insert
  # be sure to check for RETURNING in all uppercases
  def print_params(self,params):
    blue = '\033[94m'
    no_color = '\033[0m'
    print(f'{blue} SQL Params:{no_color}')
    for key, value in params.items():
      print(key, ":", value)

  def print_sql(self,title,sql):
    cyan = '\033[96m'
    no_color = '\033[0m'
    print(f'{cyan} SQL STATEMENT-[{title}]------{no_color}')
    print(sql)
  def query_commit(self,sql,params={}):
    self.print_sql('commit with returning',sql)

    pattern = r"\bRETURNING\b"
    is_returning_id = re.search(pattern, sql)

    try:
      with self.pool.connection() as conn:
        cur =  conn.cursor()
        cur.execute(sql,params)
        if is_returning_id:
          returning_id = cur.fetchone()[0]
        conn.commit() 
        if is_returning_id:
          return returning_id
    except Exception as err:
      self.print_sql_err(err)
  # when we want to return a json object
  def query_array_json(self,sql,params={}):
    self.print_sql('array',sql)

    wrapped_sql = self.query_wrap_array(sql)
    with self.pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(wrapped_sql,params)
        json = cur.fetchone()
        return json[0]
  # When we want to return an array of json objects
  def query_object_json(self,sql,params={}):

    self.print_sql('json',sql)
    self.print_params(params)
    wrapped_sql = self.query_wrap_object(sql)

    with self.pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(wrapped_sql,params)
        json = cur.fetchone()
        if json == None:
          "{}"
        else:
          return json[0]
  def query_wrap_object(self,template):
    sql = f"""
    (SELECT COALESCE(row_to_json(object_row),'{{}}'::json) FROM (
    {template}
    ) object_row);
    """
    return sql
  def query_wrap_array(self,template):
    sql = f"""
    (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (
    {template}
    ) array_row);
    """
    return sql
  def print_sql_err(self,err):
    # get details about the exception
    err_type, err_obj, traceback = sys.exc_info()

    # get the line number when exception occured
    line_num = traceback.tb_lineno

    # print the connect() error
    print ("\npsycopg ERROR:", err, "on line number:", line_num)
    print ("psycopg traceback:", traceback, "-- type:", err_type)

    # print the pgcode and pgerror exceptions
    print ("pgerror:", err.pgerror)
    print ("pgcode:", err.pgcode, "\n")

db = Db()
```

Update the home activities page for executing the queries:

`home_activities.py`
```py

from datetime import datetime, timedelta, timezone
from opentelemetry import trace
from lib.db import db, pool, query_wrap_array
import logging

#tracer = trace.get_tracer("home.activities")

class HomeActivities:
  def run(cognito_user_id=None):
    sql = db.template('activities','home')
    results = db.query_array_json(sql)
    return results

```

>I encountered errores whit the handle, and had to update the hardcoded value to my user:

![image](https://user-images.githubusercontent.com/85003009/228405849-7889241c-520e-4bd6-b86c-b077adbb2ced.png)


## Summary
- [x] Watched all the instructional videos
- [x] Create RDS Postgres Instance
- [x] Create Schema for Postgres
- [x] Watched Ashish's Week 4 - Security Considerations
- [x] Bash scripting for common database actions
- [x] Install Postgres driver in backend application
- [x] Connect Gitpod to RDS instance
- [x] Create AWS Cognito trigger to insert user into database	
- [x] Create new activities with a database insert

