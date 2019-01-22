#!/bin/bash -v
amazon-linux-extras install nginx1.12
sudo systemctl stop nginx
sed "s/REPLACE_CONTENT/$(curl http://169.254.169.254/latest/meta-data/instance-id)/" /tmp/index.html > /usr/share/nginx/html/index.html
mv /tmp/instance-info.yaml /usr/share/nginx/html/instance-info.yaml
sudo systemctl start nginx
echo 'started nginx successfully'
