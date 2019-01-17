#!/usr/bin/env bash
sudo yum -y install epel-release
sudo yum -y install nginx
sudo systemctl start nginx
echo 'started nginx successfully'
