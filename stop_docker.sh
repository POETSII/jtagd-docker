#!/bin/bash
CONTAINERS=$(docker ps -a -q -f "ancestor=jtagd")
docker stop $CONTAINERS && docker rm $CONTAINERS
