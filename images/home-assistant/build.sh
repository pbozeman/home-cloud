#!/bin/sh

# Navigate to the directory of this script
cd $(dirname $(readlink -f $0))

# Variables
REGISTRY_URL="registry.blinkies.io"
REPOSITORY_NAME="home-assistant"
IMAGE_TAG="stable"
DOCKERFILE_PATH="."

# Step 1: Build the Docker image
echo "Building Docker image..."
docker build -t $REPOSITORY_NAME:$IMAGE_TAG $DOCKERFILE_PATH

# Check if build was successful
if [ $? -ne 0 ]; then
	echo "Docker build failed, exiting..."
	exit 1
fi

# Step 2: Tag the image
echo "Tagging the image..."
docker tag $REPOSITORY_NAME:$IMAGE_TAG $REGISTRY_URL/$REPOSITORY_NAME:$IMAGE_TAG

# TODO: add a step where we check to make sure the endpoint is
# stable. On first bring up, it will likley 503 until it has
# initialized.
#
# Step 3: Login private registry
echo "Logging in to $REGISTRY_URL..."
docker login -u nobody -p none $REGISTRY_URL
if [ $? -ne 0 ]; then
	echo "Docker login failed, exiting..."
	exit 1
fi

# Step 4: Push the image
echo "Pushing the image to $REGISTRY_URL..."
docker push $REGISTRY_URL/$REPOSITORY_NAME:$IMAGE_TAG

# Check if push was successful
if [ $? -eq 0 ]; then
	echo "Image successfully pushed to $REGISTRY_URL."
else
	echo "Failed to push the image, please check the errors above."
fi
