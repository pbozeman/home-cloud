#!/bin/sh

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

# Step 2: Tag the image for your private registry
echo "Tagging the image..."
docker tag $REPOSITORY_NAME:$IMAGE_TAG $REGISTRY_URL/$REPOSITORY_NAME:$IMAGE_TAG

# Step 3: Login to your private registry
echo "Logging in to $REGISTRY_URL..."
docker login $REGISTRY_URL
if [ $? -ne 0 ]; then
	echo "Docker login failed, exiting..."
	exit 1
fi

# Step 4: Push the image to your private registry
echo "Pushing the image to $REGISTRY_URL..."
docker push $REGISTRY_URL/$REPOSITORY_NAME:$IMAGE_TAG

# Check if push was successful
if [ $? -eq 0 ]; then
	echo "Image successfully pushed to $REGISTRY_URL."
else
	echo "Failed to push the image, please check the errors above."
fi