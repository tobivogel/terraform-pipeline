#!/usr/bin/env bash
docker build -t tobi/gocd-server -f ./Dockerfile.server .
docker run --name gocd-server --network host -d tobi/gocd-server
