#!/bin/bash -v
amazon-linux-extras install nginx1.12
sudo systemctl stop nginx
mv /tmp/index.html /usr/share/nginx/html/index.html
mv /tmp/instance-info.yaml /usr/share/nginx/html/instance-info.yaml
sudo systemctl start nginx
echo 'started nginx successfully'
