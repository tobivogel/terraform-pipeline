#!/usr/bin/env bash
docker build -t tobi/gocd-agent -f ./Dockerfile.agent .
docker run -d tobi/gocd-agent
