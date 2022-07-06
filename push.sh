#!/bin/bash

TAG=$(date +%y.%m)

docker push images.canfar.net/skaha/sitelle:${TAG}
