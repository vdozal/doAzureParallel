#!/bin/bash

# Entry point for the start task. It will install the docker runtime and pull down the required docker images
# Usage:
# setup_node.sh [container_name] [container registry] [registry username] [registry password]

container_name=$1

if [ "$2" != "" ]; then
   repo_name=$2
   repo_user=$3
   repo_pass=$4
fi

apt-get -y install linux-image-extra-$(uname -r) linux-image-extra-virtual
apt-get -y install apt-transport-https
apt-get -y install curl
apt-get -y install ca-certificates
apt-get -y install software-properties-common

# Install docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get -y update
apt-get -y install docker-ce
if [ "$2" != "" ]; then
   docker login --username $repo_user --password $repo_pass $repo_name
fi
docker pull $container_name

# Check docker is running
docker info > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "UNKNOWN - Unable to talk to the docker daemon"
  exit 3
fi

# Create required directories
mkdir -p /mnt/batch/tasks/shared/R/packages
