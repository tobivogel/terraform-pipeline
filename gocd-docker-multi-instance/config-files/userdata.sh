#!/bin/bash -v
sudo yum update -y
sudo service docker start
runuser -l  ec2-user -c "docker-compose up"
