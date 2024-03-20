#!/bin/bash 
set -eux;

# Install Jenkins using docker
# based on https://www.jenkins.io/doc/book/installing/docker/

JENKINS_CONFIG_DIR=~/docker-config/jenkins;
mkdir -p $JENKINS_CONFIG_DIR;
cd $JENKINS_CONFIG_DIR;

echo "$(docker container stop jenkins)";
echo "$(docker container stop jenkins-docker)";
echo "$(docker network rm jenkins)";

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
  --publish 8080:8080 \
  --publish 50000:50000 \
  --volume  ./jenkins-data:/var/jenkins_home \
  --volume  ./jenkins-docker-certs:/certs/client:ro \
  myjenkins:lts
