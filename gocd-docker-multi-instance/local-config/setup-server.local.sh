#!/usr/bin/env bash
docker build -t tobi/gocd-server -f ./../Dockerfile.server .
docker network create -d bridge local-gocd-network
docker run --name gocd-server --net local-gocd-network -p 8153:8153 -p 8154:8154 -d tobi/gocd-server
