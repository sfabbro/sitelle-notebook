#!/bin/bash

TAG=$(date +%y.%m)
docker build \
       -t images.canfar.net/skaha/sitelle:${TAG} \
       -f Dockerfile .
