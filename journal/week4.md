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

In order to create the tables, we configure schema.sql
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

Add the postgress driver libraries to requirements.txt

```txt
psycopg[binary]
psycopg[pool]
```

Install them:

```bash
pip install -r requirements.txt
```
Then we make sure to pass the EV trough docker compose:

```yml
version: "3.8"
services:
  backend-flask:
    environment:
      CONNECTION_URL: "${CONNECTION_URL"
```

On home_activites.py we import the just created library:

```py
from lib.db import pool
```

db-connect:
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


export the ENV

```bash
export DB_SG_ID="sg-0f746e2d320a853c8"
gp env DB_SG_ID="sg-0f746e2d320a853c8"
export DB_SG_RULE_ID="sgr-093953b3b829d9584"
gp env DB_SG_RULE_ID="sgr-093953b3b829d9584"
```

rds-update-sg-rule

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
gitpod.yml
```yml
  command:
    export GITPOD_IP=$(curl ifconfig.me)
    source "$THEIA_WORKSPACE_ROOT/backend-flask/rds-update-sg-rule"
``` 
    

#### 1.4) 
#### 1.5) 
## 2) 
#### 2.1) 
#### 2.2) 
#### 2.3) 
#### 2.4) 
#### 2.5)
#### 2.7) 
#### 2.8) 
#### 2.9) 
## 3) 
#### 3.1) 
#### 3.2) 
#### 3.3) 
#### 3.4)
#### 3.5)
#### 3.6) 
## 4)
#### 4.1) 
#### 4.2) 
#### 4.3) 
#### 4.4) 

Create RDS Postgres Instance
Create Schema for Postgres
Watched Ashish's Week 4 - Security Considerations
Bash scripting for common database actions
Install Postgres driver in backend application
Connect Gitpod to RDS instance
Create AWS Cognito trigger to insert user into database	
Create new activities with a database insert


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
- [ ] Provision an RDS instance
- [ ]Temporarily stop an RDS instance
- [ ]Remotely connect to RDS instance
- [ ]Programmatically update a security group rule
- [ ]Write several bash scripts for database operations
- [ ]Operate common SQL commands
- [ ]Create a schema SQL file by hand
- [ ]Work with UUIDs and PSQL extensions
- [ ]Implement a postgres client for python using a connection pool
- [ ]Troubleshoot common SQL errors
- [ ]Implement a Lambda that runs in a VPC and commits code to RDS
- [ ]Work with PSQL json functions to directly return json from the database
- [ ]Correctly sanitize parameters passed to SQL to execute
