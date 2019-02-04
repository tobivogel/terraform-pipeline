#!/usr/bin/env bash
# BUILD server docker image
# docker login (could be automated with docker automated builds)
docker build -t tobivogel/gocd-agent -f ./Dockerfile.agent .
docker run --network host -d tobivogel/gocd-agent
# docker push tobivogel/gocd-agent

# BUILD agent docker image
# docker login (could be automated with docker automated builds)
# docker build -t tobivogel/gocd-agent -f ./Dockerfile.agent .
# docker run --network host -d tobivogel/gocd-agent
# docker push tobivogel/gocd-agent

# RUN agent docker image (on a private docker hub repo)
# "docker login" should be done on the machine provisioning - having access to the private repos should be generic
# docker run --network host -d tobivogel/gocd-agent:latest


# simple encryption
# aws kms encrypt --region ap-southeast-1 --key-id c0a08cab-2407-4e88-96dd-fda84c6c58a9 --plaintext <docker-login> --output text --query CiphertextBlob | base64 --decode > dockerEncryptedLogin.txt
# aws kms decrypt --region ap-southeast-1 --ciphertext-blob <docker-encrypted-login> --output text --query Plaintext | base64 --decode > ExamplePlaintextFile

# encryption with data keys
# create wrapped data key
# aws kms generate-data-key --region ap-southeast-1 --key-id c0a08cab-2407-4e88-96dd-fda84c6c58a9 --key-spec AES_256
# -- returns the data key in plaintext which is used to encrypt the secret we intend to protect


# aws kms encrypt --region ap-southeast-1 --key-id c0a08cab-2407-4e88-96dd-fda84c6c58a9 --plaintext fileb://docker-data-key.txt --output text --query CiphertextBlob | base64 --decode > dockerEncryptedDataKey.txt
