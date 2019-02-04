#!/bin/bash -v
sudo yum update -y
sudo amazon-linux-extras install docker
sudo service docker start
sudo usermod -a -G docker ec2-user
echo -e "$(ifconfig eth0 | grep 'inet ' | awk '{print $2}')\t$(hostname -f)" | sudo tee -a /etc/hosts
chown -R ec2-user /home/ec2-user/

runuser -l ec2-user -c "aws kms decrypt --region ap-southeast-1 --output text --query Plaintext --ciphertext-blob fileb://dockerLoginEncrypted.key | \
base64 --decode | \
docker login --username tobivogel --password-stdin"

runuser -l  ec2-user -c "docker run --name gocd-agent --network host -e GO_SERVER_URL="https://${server_ip}:8154/go" -d tobivogel/gocd-agent:latest"
