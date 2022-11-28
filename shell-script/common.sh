#!/bin/bash -e

if [ $# -ne 1 ] || [ -z $1 ];then
  echo "Pass minimum one and valid argument"
  exit 1
fi

nodever=$(echo "$1" | awk -F ',' '{  for (i=1; i<=NF; i++) print $i }' | grep "node" | grep -v grep | awk -F'=' '{print $2}' | awk -F'-' '{print $2}')
phpver=$(echo "$1" | awk -F ',' '{  for (i=1; i<=NF; i++) print $i }' | grep "php" | grep -v grep |awk -F'=' '{print $2}' | sed 's/php//g' | sed 's/-/./g')
webser=$(echo "$1" | awk -F ',' '{  for (i=1; i<=NF; i++) print $i }' | grep "webserver" | grep -v grep | awk -F'=' '{print $2}' | awk '{print tolower($0)}')

## Intalling essential packages
sudo apt install --yes software-properties-common

##
if [ "$nodever" != "No" ];then
  echo "Installing node v$nodever.x"
  curl -sL https://deb.nodesource.com/setup_$nodever.x -o nodesource_setup.sh
  sudo bash nodesource_setup.sh
  sudo apt-get install -y nodejs
  node --version
fi

##
if [ "$phpver" != "No" ];then

  export NEEDRESTART_MODE=a
  export DEBIAN_FRONTEND=noninteractive

  sudo add-apt-repository --yes ppa:ondrej/php
  sudo apt install -y php$phpver
  echo "Installing PHP-$phpver modules"

  phpmodules="common,fpm,json,cli,zip,bz2,mysql,xmlrpc,dev,imap,gd,xml,opcache,mcrypt,bcmath,curl,intl,mbstring,soap,xsl,imagick,cgi,mongodb"
  echo "Installing PHP-$phpver modules"
  echo "$phpmodules" | awk -F ',' '{ for (i=1; i<=NF; i++) system("sudo apt install -y php'$phpver'-" $i) }'
fi

##
if [ "$webser" != "No" ];then

  echo "Installing $webser"
  sudo apt install -y $webser
fi