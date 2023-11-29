#!/bin/sh

# Get the list of all completed backups, sort by creation date,
# and get the most recent one
LATEST_BACKUP=$(velero backup get --output json |
	jq -r '.items[] | select(.status.phase == "Completed") | "\(.metadata.creationTimestamp) \(.metadata.name)"' |
	sort -r | head -n 1 | awk '{print $2}')

if [ -z "$LATEST_BACKUP" ]; then
	echo "No successful backups found."
	exit 1
fi

echo "Latest successful backup: $LATEST_BACKUP"
