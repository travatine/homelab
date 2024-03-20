PUB_KEY="$(cat ~/docker-config/jenkins/jenkins_agent_key.pub)";
docker run -d \
 --name=agent1 \
 -p 4444:22 \
 --restart=on-failure \
 -e "JENKINS_AGENT_SSH_PUBKEY=$PUB_KEY" \
 jenkins/ssh-agent:latest;
