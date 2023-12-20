#!/bin/sh

SCHEDULE_NAME="daily-home"
SCHEDULE_TIME="0 3 * * *"
NAMESPACES="home-automation,media,apps"

# Check if the schedule already exists
velero schedule get $SCHEDULE_NAME >/dev/null 2>&1
if [ $? -eq 0 ]; then
	echo "Schedule '$SCHEDULE_NAME' already exists. Skipping creation."
else
	velero schedule create $SCHEDULE_NAME --schedule="$SCHEDULE_TIME" --include-namespaces "$NAMESPACES"
fi
