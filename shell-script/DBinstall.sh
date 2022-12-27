#!/bin/bash -e

if [ $# -ne 1 ] || [ -z $1 ];then
  echo "Pass minimum one and valid argument"
  exit 1
fi


## DB Type
DatabaseType=$(echo "$1" | sed 's/,/\n/g' | grep -i DatabaseType= | awk -F'=' '{print $2}')

if [ "$DatabaseType" != "MongoDB" ] && [ "$DatabaseType" != "MYSQL" ];then
  echo "Selected DB type not mongodb or mysql"
  exit 0
fi

## Fetch DB details
# echo "DatabaseType=Mongodb,DBName=test1,DBUser1=mahek,DBUser1Password=mahek123" | sed 's/,/\n/g' | grep -i DatabaseType | awk -F'=' '{print $2}'

## User1
DBName=$(echo "$1" | sed 's/,/\n/g' | grep -i DBName= | awk -F'=' '{print $2}')
DBUser1=$(echo "$1" | sed 's/,/\n/g' | grep -i DBUser1= | awk -F'=' '{print $2}')
DBUser1Password=$(echo "$1" | sed 's/,/\n/g' | grep -i DBUser1Password= | awk -F'=' '{print $2}')

## Admin user Password
DBAdminUser=$(echo "$1" | sed 's/,/\n/g' | grep -i DBAdminUser= | awk -F'=' '{print $2}')

## Admin user Password
DBAdminPassword=$(echo "$1" | sed 's/,/\n/g' | grep -i DBAdminPassword= | awk -F'=' '{print $2}')

DBEndpoint=$(echo "$1" | sed 's/,/\n/g' | grep -i DBEndpoint= | awk -F'=' '{print $2}')
##
if [ "${DatabaseType}" == "MongoDB" ];then
  if [ "$(echo $1 | sed 's/,/\n/g' | wc -l)" -ne 5 ];then
    echo "Please pass all 5 value in argument sperated by comma"
    exit 0
  fi

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
  memallocate=$(printf "%0.2f\n" $(echo "scale=2; $TotalMemory / $divideby" | bc))
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

mongosh --quiet --eval <<EOF
  use ${DBName}
  db.createUser({ user: "${DBUser1}", pwd: "${DBUser1Password}", roles: [ { role: "readWrite", db: "${DBName}" } ]})
EOF

## Create admin user
mongosh --quiet --eval <<EOF
  use admin
  db.createUser({ user: "admin" , pwd: "${DBAdminPassword}", roles: ["userAdminAnyDatabase", "dbAdminAnyDatabase", "readWriteAnyDatabase"]})
EOF

  ## Enable security
  if [ $(grep -i "^security:" $mongoconf | wc -l) -ne 1 ];then
    echo "security:" >> $mongoconf
    echo "  authorization: \"enabled\"" >> $mongoconf
  fi

  # mongo --eval 'db.runCommand({ connectionStatus: 1 })'
elif [ "${DatabaseType}" == "MYSQL" ];then
  echo "CREATE USER '${DBUser1}'@'%' IDENTIFIED WITH mysql_native_password BY '${DBUser1Password}';" > /tmp/createuser.sql
  echo "GRANT ALL PRIVILEGES ON `%`.* To '${DBUser1}'@'%';" >> /tmp/createuser.sql
  echo "FLUSH PRIVILEGES;" >> /tmp/createuser.sql

  mysql -h"${DBEndpoint}" -u"${DBAdminUser}" -p"${DBAdminPassword}" < /tmp/createuser.sql

else
  echo "Wrong database type value passed"
  exit 0
fi