#!/bin/bash -e

if [ $# -ne 1 ] || [ -z $1 ];then
  echo "Pass minimum one and valid argument"
  exit 1
fi

nodever=$1

echo "node version: $nodever"
cd /tmp/
curl -sL https://deb.nodesource.com/setup_$nodever.x -o nodesource_setup.sh
sudo bash nodesource_setup.sh
sudo apt-get install -y nodejs
