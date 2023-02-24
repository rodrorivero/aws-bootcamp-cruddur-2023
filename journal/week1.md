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

![image](https://user-images.githubusercontent.com/85003009/221087227-f48ecab6-3183-49ce-a7d3-616157f1e013.png)

### Built container and contenerized Front End and Back End:



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

![image](https://user-images.githubusercontent.com/85003009/221087549-f16b9664-2eff-4425-80bb-4a8c7d4b8d39.png)


![image](https://user-images.githubusercontent.com/85003009/221087700-02098d94-3c56-4bd2-bff1-26f6aa9df98b.png)


> Testing the Front End:

![image](https://user-images.githubusercontent.com/85003009/221087787-53e59824-9ef9-4b0f-81b5-f426d67eb855.png)


> Commit changes:

![image](https://user-images.githubusercontent.com/85003009/221085828-aff4e626-6d97-4dae-8e47-21a90010979d.png)

[Link to Lucidchart](https://lucid.app/lucidchart/8ab7b0e9-dc68-44a1-8411-61ff335cefcd/edit?viewport_loc=1197%2C326%2C2501%2C1180%2C0_0&invitationId=inv_d5f80eb6-d1d6-4b37-99b0-d9b0189f442c)

## Summary
- [x] Watched all the instructional videos
- [x] Installed VSCode Docker extension
- [x] Built container and contenerized Front End and Back End
- [x] Installed AWS CLI	
- [x] Create a Billing Alarm and a budget
