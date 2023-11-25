#!/bin/sh
#
# This is for running the image during development

docker run \
	--restart=unless-stopped \
	-v ./.config:/config \
	--network=host \
	blinkies/home-assistant:stable
