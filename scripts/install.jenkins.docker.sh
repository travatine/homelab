#!/bin/bash
set -eux;

# Install Jenkins using docker
# based on https://www.jenkins.io/doc/book/installing/docker/

JENKINS_CONFIG_DIR=~/docker-config/jenkins;
JENKINS_AGENT_CONFIG_DIR=~/docker-config/jenkins-agent;
mkdir -p $JENKINS_CONFIG_DIR;
cd $JENKINS_CONFIG_DIR;

echo "$(docker container stop jenkins)";
echo "$(docker container rm jenkins)";
#sleep 3
echo "$(docker container stop jenkins-docker)";
echo "$(docker container rm jenkins-docker)";

echo "$(docker container stop agent1)";
echo "$(docker container rm agent1)";
#sleep 3
echo "$(docker network rm jenkins)";
#sleep 3

docker network create jenkins

docker run \
  --name jenkins-docker \
  --rm \
  --detach \
  --privileged \
  --network jenkins \
  --network-alias docker \
  --env DOCKER_TLS_CERTDIR=/certs \
  --volume ./jenkins-docker-certs:/certs/client \
  --volume ./jenkins-data:/var/jenkins_home \
  --publish 2376:2376 \
  docker:dind \
  --storage-driver overlay2

# Create custom docker file with docker cli and jenkins plugin for docker

cat << 'EOF' > $JENKINS_CONFIG_DIR/Dockerfile
FROM jenkins/jenkins:lts
USER root
RUN apt-get update && apt-get install -y lsb-release
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
  https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
RUN apt-get update && apt-get install -y docker-ce-cli
USER jenkins
RUN jenkins-plugin-cli --plugins "docker-workflow"
EOF

# build custom container
docker build -t myjenkins:lts .

docker run \
  --name jenkins \
  --restart=on-failure \
  --detach \
  --network jenkins \
  --env DOCKER_HOST=tcp://docker:2376 \
  --env DOCKER_CERT_PATH=/certs/client \
  --env DOCKER_TLS_VERIFY=1 \
  --env JAVA_OPTS="-Xmx2048m -Djava.awt.headless=true" \
  --publish 8080:8080 \
  --publish 50000:50000 \
  --volume  ./jenkins-data:/var/jenkins_home \
  --volume  ./jenkins-docker-certs:/certs/client:ro \
  myjenkins:lts

# display initial admin key
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

hostname -I;
echo 'Go to http:// <ip address>:8080/';
echo 'Choose - Install recommended plugins';
echo 'Create admin user';
echo 'Choose default instance address';
echo 'Start using Jenkins';
echo ''


mkdir -p $JENKINS_AGENT_CONFIG_DIR;
cd $JENKINS_AGENT_CONFIG_DIR;

cat << 'EOF' > $JENKINS_AGENT_CONFIG_DIR/Dockerfile
FROM jenkins/ssh-agent
USER root
RUN apt-get update
RUN apt-get install -y python3 \
                       python-is-python3 \
                       python3-venv
# Install wget
#RUN apt-get install -y wget
# Get Chrome
#RUN apt-get install -y gnupg
#RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
#RUN sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
#RUN apt-get update
#RUN apt-get install -y google-chrome-stable

# installing google-chrome-stable
RUN apt-get install -y gnupg wget curl unzip --no-install-recommends; \
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | \
    gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/google.gpg --import; \
    chmod 644 /etc/apt/trusted.gpg.d/google.gpg; \
    echo "deb https://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list; \
    apt-get update -y; \
    apt-get install -y google-chrome-stable;

# installing chromedriver
RUN CHROMEDRIVER_VERSION=$(curl https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_STABLE); \
    wget -N https://storage.googleapis.com/chrome-for-testing-public/$CHROMEDRIVER_VERSION/linux64/chromedriver-linux64.zip -P ~/ && \
    unzip ~/chromedriver-linux64.zip -d ~/ && \
    rm ~/chromedriver-linux64.zip && \
    mv -f ~/chromedriver-linux64/chromedriver /usr/bin/chromedriver && \
    rm -rf ~/chromedriver-linux64
EOF

# build custom container
docker build -t myjenkinsagent:lts .

PUB_KEY="$(cat ~/docker-config/jenkins/jenkins_agent_key.pub)";
docker run -d \
 --name=agent1 \
 -p 4444:22 \
 --restart=on-failure \
 -e "JENKINS_AGENT_SSH_PUBKEY=$PUB_KEY" \
 myjenkinsagent:lts;
