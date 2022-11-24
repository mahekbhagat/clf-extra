#!/bin/bash -e

if [ $# -ne 1 ];then
  echo "Pass single parameter"
  exit 1
fi

if [ -n $1 ];then
  nodever=$(echo "node-14-xx-lts" | grep -e "node-[1-9][0-9]-xx-lts" | grep -v grep | awk -F'-' '{print $2}')
  echo "Installing node $nodever.x"
else
  echo "Invalid Parmeter"
  exit 1
fi

echo "node version"
cd /tmp/
curl -sL https://deb.nodesource.com/setup_$nodever.x -o nodesource_setup.sh
sudo bash nodesource_setup.sh
sudo apt-get install -y nodejs