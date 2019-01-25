#!/usr/bin/env bash
docker build -t tobi/gocd-agent -f ./Dockerfile.agent .
docker run --net local-gocd-network -e GO_SERVER_URL=https://gocd-server:8154/go -d tobi/gocd-agent
