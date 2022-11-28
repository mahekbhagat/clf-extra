#!/bin/bash -e

if [ $# -ne 1 ] || [ -z $1 ];then
  echo "Pass minimum one and valid argument"
  exit 1
fi

nodever=$(echo "$1" | awk -F ',' '{  for (i=1; i<=NF; i++) print $i }' | grep -e "node-[1-9][0-9]-xx-lts" | grep -v grep | awk -F'-' '{print $2}')
phpver=$(echo "$1" | awk -F ',' '{  for (i=1; i<=NF; i++) print $i }' | grep -e "[1-9]\{1,2\}-[0-9]" | grep -v grep | sed 's/php//g' | sed 's/-/./g')
webser=$(echo "$1" | awk -F ',' '{  for (i=1; i<=NF; i++) print $i }' | grep -e "Nginx\|Apache2" | grep -v grep | awk '{print tolower($0)}')

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
  echo "$phpmodules" | awk -F ',' '{ for (i=1; i<=NF; i++) system("sudo apt install --yes php'$phpver'-" $i) }'
fi

##
if [ "$webser" != "No" ];then

  echo "Installing $webser"
  sudo apt install -y $webser
fi