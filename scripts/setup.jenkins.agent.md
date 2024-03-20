# Installing a Jenkins agent

( based on https://www.jenkins.io/doc/book/using/using-agents/ )

## Generate SSH Key
- On jenkins host VM - generate SSH Key

```
ssh-keygen -f ~/docker-config/jenkins/jenkins_agent_key
```

- Go to http://192.168.7.124:8080/
- Click Manage Jenkins > Credentials
- Under Global > Add Credentials
  - Kind: SSH Username with private key;
  - id: jenkins
  - Description: The jenkins ssh key
  - Username: jenkins
  - Private Key : enter directly > Click Add
- Paste contents of  ~/docker-config/jenkins/jenkins_agent_key
- Click Create

## Start the agent using Docker

```
# Get public ssh key
PUB_KEY="$(cat ~/docker-config/jenkins/jenkins_agent_key.pub)";

# Create an agent
docker run -d --rm --name=agent1 -p 4444:22 \
-e "JENKINS_AGENT_SSH_PUBKEY=$PUB_KEY" \
jenkins/ssh-agent:latest;
docker ps;
```

## Setup up the agent1 on jenkins.

- Go to Jenkins e.g. http://192.168.7.124:8080/
- Manage Jenkins > Nodes
- New Node
  - Name: agent1
  - Type : Permanent 
- Click Create

Specify the node attributes
- Remote root directory: /home/jenkins/agent
- Labels: agent1
- Usage: Only build jobs with label expressions matching this node
- Launch method: Launch agents via SSH
- Host: 192.168.7.124
- Credentials: jenkins
- Host Key verification Strategy;  Manually trusted key verification 
- Click Advanced > Port 4444
- Click Save

Wait 10 seconds and then refresh the page

Click the node - click Trust SSH Key

The node should appear on this page http://192.168.7.124:8080/computer/
with status as online.

## Create a build to test the agent

Jenkins > New Item
 - Item name: test 
 - Type Freestyle project
 - Click OK

Tick 'Restrict where this project can be run' , 
Label Expression 'agent1'

Add Build Step > Execute Shell

Add command: echo $NODE_NAME
Click Save

Click Build Now

## Disable the built in node executors

http://192.168.7.124:8080/
Click Manage Jenkins
Click Nodes
Click Built In Node
Click Configure
Number of executors 0
Click Save

Wait 5 seconds, click the build that ran

Click Console

Should see agent1 in the console output.
