#!/bin/bash

version=$1

docker container run \
  --name istioctl \
  --rm \
  -v "$PWD":"$PWD" \
  -w "$PWD" \
  istio/istioctl:$version \
    manifest -f ./$version/custom-config.yaml generate > ./$version/generated-manifest.yaml
    # profile list
    # profile dump default > tes.yaml
    
