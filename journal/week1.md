```
                                                                                                                                  
   :7YPGGGGGP5?: JGGGGGGGGGPP5J~.  JGGGGG7  ~GGGGG5  5GGGGGGGGP5Y7:    PGGGGGGGGP5Y!.    PGGGGG:  ?GGGGG? .GGGGGGGGGGP5Y7:     
 .5BBBGGBBBBBBB^ JBGGGGGPPGGGGBBG: YBGGGB?  !BGGGGP  PBGGGGBBBBGBBBY.  GGGGGGBBBBGBBBY.  GGGGGB:  JBGGGBJ :BGGGGGPPPGGGBBBJ    
.GBGGGGGJ!^~!?J  JBGGGG5::~GGGGGB? YBGGGB?  ~BGGGGP  PGGGGBY~7PGGGGBG. GGGGGG?^75GGGGBP  GGGGGB:  JBGGGBJ :BGGGGG~.:JBGGGGB.   
^BGGGGB7         JBGGGGGGGGGGGGG5. YBGGGB?  ~BGGGGP  PGGGGB!  .GGGGGB^ GGGGGB:  .GGGGGB^ GGGGGB^  JBGGGBJ :BGGGGGGGGGGGGGG!    
.GBGGGGP?~:^~7?  JBGGGGPYGGGGGB!   !BGGGGP~^5GGGGBJ  PGGGGBJ:!5GGGGBG. GGGGGB7:!5GGGGBG. 5BGGGG5^!GGGGGB~ :BGGGGG55BGGGG5.     
 :5BBGGGBBBBBBB^ JBGGGB? :GGGGGP.   JBBGGGBBGGGBB5.  PGGGGGGBBBGBBB5:  GGGGGGBBBBGBBB5:  .5BBGGGBBGGGBB?  :BGGGGG. JBGGGG7     
   ^?5GGGGGGGPJ: JGGGGG?  ^GGGGGP.   :?5GGGGGGPJ^    5GGGGGGGGGPY?:    PGGGGGGGGGPY7:      ~Y5GGGGGP5?:   .GGGGGG.  5GGGGG7       
                                                                                                                                  
```  
# Week 1 — App Containerization
## Required Homeworks/Taks                                                                                                                
### Installed VSCode Docker extension:

To install the Docker extension in VSCode, search for "Docker" in the extensions sidebar, click "Install," and then click "Reload" after installation.

![image](https://user-images.githubusercontent.com/85003009/221087227-f48ecab6-3183-49ce-a7d3-616157f1e013.png)

### Built container and contenerized Front End and Back End:

We used Docker to containerize our website, made with Flask framework, for that we have separated Dockerfiles for frontend and backend, first we built the Docker images using docker build, and then ran the containers using docker run. 

Dockerfile code Front End:

```Dockerfile
FROM node:16.18
ENV PORT=3000
COPY . /frontend-react-js
WORKDIR /frontend-react-js
RUN npm install
EXPOSE ${PORT}
CMD ["npm", "start"]
```
Dockerfile code Back End:

```Dockerfile
FROM python:3.10-slim-buster
WORKDIR /backend-flask
COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt
COPY . .
ENV FLASK_ENV=development
EXPOSE ${PORT}
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=4567"]
```

Docker Compose was used for defining our multi container application in a docker-compose.yml file and start both images with a single command using docker-compose up. At the end we ensure that the back end and front end containers can communicate with each other testing using port mapping to expose both.

Docker composer file:

```yml
version: "3.8"
services:
  backend-flask:
    environment:
      FRONTEND_URL: "https://3000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
      BACKEND_URL: "https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
    build: ./backend-flask
    ports:
      - "4567:4567"
    volumes:
      - ./backend-flask:/backend-flask
  frontend-react-js:
    environment:
      REACT_APP_BACKEND_URL: "https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
    build: ./frontend-react-js
    ports:
      - "3000:3000"
    volumes:
      - ./frontend-react-js:/frontend-react-js

networks: 
  internal-network:
    driver: bridge
    name: cruddur
```

> Docker compose execution:

![image](https://user-images.githubusercontent.com/85003009/221087549-f16b9664-2eff-4425-80bb-4a8c7d4b8d39.png)


> Check the exposed ports an make sure to unlock them in order to enable external access:

![image](https://user-images.githubusercontent.com/85003009/221087700-02098d94-3c56-4bd2-bff1-26f6aa9df98b.png)


> Testing the Front End:

![image](https://user-images.githubusercontent.com/85003009/221087787-53e59824-9ef9-4b0f-81b5-f426d67eb855.png)


When using Git it's important to commit all the changes and write a message in order to maintain consistency in the repository. 

> Commit changes:

![image](https://user-images.githubusercontent.com/85003009/221085828-aff4e626-6d97-4dae-8e47-21a90010979d.png)

### Create Notification Feature:

##On the Backend:

Added and endpoint using Open API (openapi-3.0.yml):

```yml
  /api/activities/notifications:
      get:
        description: 'Return a feed of activity for all of those that I follow'
        tags:
          - activities
        parameters: []
        responses:
          '200':
           description: Returns an array of activites
           content:
             application/json:   
               schema:
                type: array
                items:
                  $ref: '#/components/schemas/Activity'
```

Define the call to the notifications module (app.py):

```py
@app.route("/api/activities/notifications", methods=['GET'])
def data_notifications():
  data = NotificationsActivities.run()
  return data, 200
```

Create a service with mock data for the module (motifications_activities.py):

```py
from datetime import datetime, timedelta, timezone
class NotificationsActivities:
  def run():
    now = datetime.now(timezone.utc).astimezone()
    results = [{
      'uuid': '68f126b0-1ceb-4a33-88be-d90fa7109eee',
      'handle':  'Mark Green',
      'message': 'I love to write code! ...not!',
      'created_at': (now - timedelta(days=2)).isoformat(),
      'expires_at': (now + timedelta(days=5)).isoformat(),
      'likes_count': 5,
      'replies_count': 1,
      'reposts_count': 0,
      'replies': [{
        'uuid': '26e12864-1c26-5c3a-9658-97a10f8fea67',
        'reply_to_activity_uuid': '68f126b0-1ceb-4a33-88be-d90fa7109eee',
        'handle':  'Worf',
        'message': 'This post has no honor!',
        'likes_count': 0,
        'replies_count': 0,
        'reposts_count': 0,
        'created_at': (now - timedelta(days=2)).isoformat()
      }],
    }
    ]
    return results
```

##On the Front End:

Create route on route router file for rendering the page (App.js):

```py
import NotificationsFeedPage from './pages/NotificationsFeedPage';

const router = createBrowserRouter([
  {
    path: "/Notifications",
    element: <NotificationsFeedPage />
  },
]);
```

Create the page for calling the module on the backend (NotificationsFeedPage.js) :

```js
import './NotificationsFeedPage.css';
import React from "react";

import DesktopNavigation  from '../components/DesktopNavigation';
import DesktopSidebar     from '../components/DesktopSidebar';
import ActivityFeed from '../components/ActivityFeed';
import ActivityForm from '../components/ActivityForm';
import ReplyForm from '../components/ReplyForm';

// [TODO] Authenication
import Cookies from 'js-cookie'

export default function HomeFeedPage() {
  const [activities, setActivities] = React.useState([]);
  const [popped, setPopped] = React.useState(false);
  const [poppedReply, setPoppedReply] = React.useState(false);
  const [replyActivity, setReplyActivity] = React.useState({});
  const [user, setUser] = React.useState(null);
  const dataFetchedRef = React.useRef(false);

  const loadData = async () => {
    try {
      const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/activities/notifications`
      const res = await fetch(backend_url, {
        method: "GET"
      });
      let resJson = await res.json();
      if (res.status === 200) {
        setActivities(resJson)
      } else {
        console.log(res)
      }
    } catch (err) {
      console.log(err);
    }
  };

  const checkAuth = async () => {
    console.log('checkAuth')
    // [TODO] Authenication
    if (Cookies.get('user.logged_in')) {
      setUser({
        display_name: Cookies.get('user.name'),
        handle: Cookies.get('user.username')
      })
    }
  };

  React.useEffect(()=>{
    //prevents double call
    if (dataFetchedRef.current) return;
    dataFetchedRef.current = true;

    loadData();
    checkAuth();
  }, [])

  return (
    <article>
      <DesktopNavigation user={user} active={'home'} setPopped={setPopped} />
      <div className='content'>
        <ActivityForm  
          popped={popped}
          setPopped={setPopped} 
          setActivities={setActivities} 
        />
        <ReplyForm 
          activity={replyActivity} 
          popped={poppedReply} 
          setPopped={setPoppedReply} 
          setActivities={setActivities} 
          activities={activities} 
        />
        <ActivityFeed 
          title="Home" 
          setReplyActivity={setReplyActivity} 
          setPopped={setPoppedReply} 
          activities={activities} 
        />
      </div>
      <DesktopSidebar user={user} />
    </article>
  );
}
```
Testing the notifications page :

![image](https://user-images.githubusercontent.com/85003009/221100384-1dbc56f9-064e-4c1a-b579-fe0da9312746.png)

### Run DynamoDB and Postgress local Containers

##Dynamo DB:

Edited docker-compose file

```yml
dynamodb-local:
    # https://stackoverflow.com/questions/67533058/persist-local-dynamodb-data-in-volumes-lack-permission-unable-to-open-databa
    # We needed to add user:root to get this working.
    user: root
    command: "-jar DynamoDBLocal.jar -sharedDb -dbPath ./data"
    image: "amazon/dynamodb-local:latest"
    container_name: dynamodb-local
    ports:
      - "8000:8000"
    volumes:
      - "./docker/dynamodb:/home/dynamodblocal/data"
    working_dir: /home/dynamodblocal
```
> Make sure 8000 port is set to public:

![image](https://user-images.githubusercontent.com/85003009/221329655-8b8b526c-58ca-4ce9-8b52-070e5680a953.png)

Testing the connection to local database:

![image](https://user-images.githubusercontent.com/85003009/221330291-78936d36-5c0c-4833-a5f6-7a0f16aed06a.png)

##Dynamo DB:

Edited docker-compose file

```yml
  db:
    image: postgres:13-alpine
    restart: always
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    ports:
      - '5432:5432'
    volumes: 
      - db:/var/lib/postgresql/data  
```

Added the installation of driver for postgres on .gitpod.yml file in order to install everytime the environment is provisioned:

```yml
  - name: postgres
    init: |
      curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
      echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list
      sudo apt update
      sudo apt install -y postgresql-client-13 libpq-dev
```

Test the connection to postgres database:

![image](https://user-images.githubusercontent.com/85003009/221341946-9b12e2bc-1a8b-4ba0-859a-b504d06363f8.png)


## Summary
- [x] Watched all the instructional videos
- [x] Installed VSCode Docker extension
- [x] Built container and contenerized Front End and Back End
- [x] Create the notification feature
- [x] Run DynamoDB and Postgress local Containers

[Link to Lucidchart](https://lucid.app/lucidchart/8ab7b0e9-dc68-44a1-8411-61ff335cefcd/edit?viewport_loc=1197%2C326%2C2501%2C1180%2C0_0&invitationId=inv_d5f80eb6-d1d6-4b37-99b0-d9b0189f442c)
