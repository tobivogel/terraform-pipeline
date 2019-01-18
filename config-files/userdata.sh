#!/bin/bash -v
amazon-linux-extras install nginx1.12
sudo systemctl start nginx
echo 'started nginx successfully'
