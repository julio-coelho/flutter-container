#!/usr/bin/env bash

set -eo pipefail

# args NAME PROJECTID path (tag/hash)

pushd $3

NAME=$1
PROJECT_ID=$2
TAG=$4

echo "building $NAME within $PROJECT_ID tag $TAG  path $3"

docker build -t avenuesec/$NAME:$TAG .

docker tag avenuesec/$NAME:$TAG us.gcr.io/${PROJECT_ID}/$NAME:$TAG

docker push us.gcr.io/${PROJECT_ID}/$NAME:$TAG