#!/usr/bin/env bash
docker build -t tobi/gocd-agent -f ./Dockerfile.agent .
docker run --net local-gocd-network -d tobi/gocd-agent
