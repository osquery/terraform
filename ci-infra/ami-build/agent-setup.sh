#!/bin/bash

set -ex

cat <<EOF > /tmp/preseed.cfg
debconf debconf/frontend select Noninteractive
tzdata tzdata/Areas select Etc
tzdata tzdata/Zones/Etc select UTC
EOF

sudo debconf-set-selections /tmp/preseed.cfg

ARCH=$(dpkg --print-architecture)

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
apt-get install -y tzdata
sudo apt-get -y upgrade

echo "Installing required packages for apt repos"
sudo apt-get install -y apt-transport-https ca-certificates gnupg-agent software-properties-common curl

curl -L https://download.docker.com/linux/ubuntu/gpg \
    | sudo apt-key add -
sudo apt-key adv --list-public-keys --with-fingerprint --with-colons 0EBFCD88 2>/dev/null \
    | grep 'fpr' | head -n1 | grep '9DC858229FC7DD38854AE2D88D81803C0EBFCD88'
sudo add-apt-repository -y "deb [arch=${ARCH}] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-add-repository -y ppa:git-core/ppa

sudo apt-get update

echo "Installing docker"
sudo apt-get install -y docker-ce docker-ce-cli git awscli jq inotify-tools

sudo mkdir -p /etc/docker
echo '{
  "ipv6": true,
  "fixed-cidr-v6": "2001:db8:1::/64"
}' | sudo tee /etc/docker/daemon.json
echo "::1 localhost" | sudo tee -a /etc/hosts

sudo systemctl enable docker
##FIXME##sudo systemctl start docker

sudo useradd -ms /bin/bash -G docker github-runner
sudo mkdir -p /srv/runner
sudo chown -R github-runner:github-runner /srv/runner/

##
## Setup GitHub Runner Agent
##

# Normalize ARCH variable
[[ "${ARCH}" == "amd64" ]] && ARCH=x64

AGENT_VERSION=2.277.1
AGENT_FILE=actions-runner-linux-${ARCH}-${AGENT_VERSION}.tar.gz

curl -L https://github.com/actions/runner/releases/download/v${AGENT_VERSION}/${AGENT_FILE} \
     | sudo -u github-runner tar xz -C /srv/runner

sudo /srv/runner/bin/installdependencies.sh


# Setup github ssh key. Not totally sure we need it, but...
sudo -u github-runner mkdir /home/github-runner/.ssh
ssh-keyscan github.com \
    | sudo -u github-runner tee /home/github-runner/.ssh/known_hosts



sudo chown root:root /srv/runner/tmpscripts/*.sh
sudo chmod 0755 /srv/runner/tmpscripts/*.sh
sudo mv /srv/runner/tmpscripts/*.sh /usr/local/bin

rm -rf /srv/runner/tmpscripts
