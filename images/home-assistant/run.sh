#!/bin/sh
#
# This is for running the image during development

REGISTRY_URL="registry.blinkies.io"
REPOSITORY_NAME="home-assistant"
IMAGE_TAG="stable"

docker run \
	--restart=unless-stopped \
	-v ./.config:/config \
	--network=host \
	$REPOSITORY_NAME:$IMAGE_TAG
