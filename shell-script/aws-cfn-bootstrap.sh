#!/bin/bash -e

##
## Created By: Mahek Bhagat
## Last Modified By: Mahek Bhagat
## Created Date: 2022-11-29
## Last Modified Dtae: 2022-11-29
## Purpose: Install cfn-bootstrap and cfn-init for ubuntu
##

export NEEDRESTART_MODE=a
export DEBIAN_FRONTEND=noninteractive

apt-get install -y build-essential python3-pip python3-setuptools needrestart

# Restart any pending service
needrestart -u NeedRestart::UI::stdio -r a
pip install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-py3-latest.tar.gz

if [ $? -eq 0 ];then
  echo "Successfully installed aws-cfn-bootstrap-py3"
fi