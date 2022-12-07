#!/bin/bash -e

if [ $# -ne 1 ] || [ -z $1 ];then
  echo "Pass minimum one and valid argument"
  exit 1
fi

if [ "$(echo $1 | sed 's/,/\n/g' | wc -l)" -ne 5 ];then
  echo "Please pass all 5 value in argument sperated by comma"
  exit 0
fi
# echo "DB_TYPE=Mongodb,DB_USER1=mahek,DB_PWD1=mahek123,DB_NM1=test1" | sed 's/,/\n/g' | grep -i DB_TYPE | awk -F'=' '{print $2}'

## DB Type
DB_TYPE= $(echo "$1" | sed 's/,/\n/g' | grep -i DB_TYPE | awk -F'=' '{print $2}')

if [ "$DB_TYPE" != "MongoDB" ];then
  echo "DB type not mongodb"
  exit 0
fi

## User1
DB_USER1=$(echo "$1" | sed 's/,/\n/g' | grep -i DB_USER1 | awk -F'=' '{print $2}')
DB_PWD1=$(echo "$1" | sed 's/,/\n/g' | grep -i DB_PWD1 | awk -F'=' '{print $2}')
DB_NM1=$(echo "$1" | sed 's/,/\n/g' | grep -i DB_NM1 | awk -F'=' '{print $2}')

## Admin user
DB_PWD2=$(echo "$1" | sed 's/,/\n/g' | grep -i DB_PWD2 | awk -F'=' '{print $2}')

## Ubuntu code name
os_code=`cat /etc/os-release | grep -i "UBUNTU_CODENAME" | awk -F'=' '{print $2}'`

echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu ${os_code}/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 6A26B1AE64C3C388
sudo apt-get update
sudo apt-get install -y mongodb-org

echo "mongodb-org hold" | sudo dpkg --set-selections
echo "mongodb-org-database hold" | sudo dpkg --set-selections
echo "mongodb-org-server hold" | sudo dpkg --set-selections
echo "mongodb-mongosh hold" | sudo dpkg --set-selections
echo "mongodb-org-mongos hold" | sudo dpkg --set-selections
echo "mongodb-org-tools hold" | sudo dpkg --set-selections

## Allocate 1/4 of ram memory to mongo
mongoconf="/etc/mongod.conf"
TotalMemory=`free --giga | grep -i "Mem" | awk '{print $2}'`
divideby=4
memallocate=$(printf "%0.2f\n" $(echo "scale=1; $TotalMemory / $divideby" | bc))
echo "$memallocate"

if [ $(grep -i '^  journal:' $mongoconf | wc -l) -eq 1 ];then
	echo "Skip adding journal"
else
	sed -i 's/storage:/storage:\n  journal:\n    enabled: true/g' $mongoconf
fi

if [ $(grep -i "^  wiredTiger:" $mongoconf | wc -l) -ne 1 ];then
	sed -i 's/#  wiredTiger:/  wiredTiger:\n    engineConfig:\n      cacheSizeGB: '$memallocate'/g' $mongoconf
else
	echo "Found wiredTiger in config. Memory already allocated"
fi

## start and enable mongod service
systemctl start mongod 
systemctl enable mongod

##
## create user

if [ $(grep -i "^security:" $mongoconf | wc -l) -ne 1 ];then
  echo "security:" >> $mongoconf
  echo "  authorization: \"enabled\"" >> $mongoconf
fi

mongosh --quiet --eval <<EOF
  use ${DB_NM1}
  db.createUser({ user: "${DB_USER1}", pwd: "${DB_PWD1}", roles: [ { role: "readWrite", db: "${DB_NM1}" } ]})
EOF

## Create admin user
mongosh --quiet --eval <<EOF
  use admin
  db.createUser({ user: "admin" , pwd: "${DB_PWD2}", roles: ["userAdminAnyDatabase", "dbAdminAnyDatabase", "readWriteAnyDatabase"]})
EOF

# mongo --eval 'db.runCommand({ connectionStatus: 1 })'