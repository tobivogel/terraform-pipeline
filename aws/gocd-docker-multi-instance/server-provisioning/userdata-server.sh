#!/bin/bash -v
sudo yum update -y
sudo amazon-linux-extras install docker
sudo service docker start
sudo usermod -a -G docker ec2-user
echo -e "$(ifconfig eth0 | grep 'inet ' | awk '{print $2}')\t$(hostname -f)" | sudo tee -a /etc/hosts
chown -R ec2-user /home/ec2-user/
chmod +x /home/ec2-user/setup-server.sh
runuser -l  ec2-user -c "./setup-server.sh"
