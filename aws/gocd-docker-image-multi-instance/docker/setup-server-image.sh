#!/usr/bin/env bash
# BUILD server docker image
# docker login (could be automated with docker automated builds)
# docker build -t tobivogel/gocd-server -f ./Dockerfile.server .
# docker run --name gocd-server --network host -d tobivogel/gocd-server
# docker push tobivogel/gocd-server

# RUN server docker image (on a public docker hub repo)
# docker run --name gocd-server --network host -d tobivogel/gocd-server:latest
