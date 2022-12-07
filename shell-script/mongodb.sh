#!/bin/bash -e

if [ $# -ne 1 ] || [ -z $1 ];then
  echo "Pass minimum one and valid argument"
  exit 1
fi

echo "Mongodb latest version"

os_code=`cat /etc/os-release | grep -i "UBUNTU_CODENAME" | awk -F'=' '{print $2}'`

echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu ${os_code}/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org

echo "mongodb-org hold" | sudo dpkg --set-selections
echo "mongodb-org-database hold" | sudo dpkg --set-selections
echo "mongodb-org-server hold" | sudo dpkg --set-selections
echo "mongodb-mongosh hold" | sudo dpkg --set-selections
echo "mongodb-org-mongos hold" | sudo dpkg --set-selections
echo "mongodb-org-tools hold" | sudo dpkg --set-selections

# mongo --eval 'db.runCommand({ connectionStatus: 1 })'