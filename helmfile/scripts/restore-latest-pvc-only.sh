#!/bin/sh

# Get the list of all completed backups, sort by creation date,
# and get the most recent one
LATEST_BACKUP=$(velero backup get --output json |
	jq -r '.items[] | select(.status.phase == "Completed") | "\(.status.completionTimestamp) \(.metadata.name)"' |
	sort -r | head -n 1 | awk '{print $2}')

if [ -z "$LATEST_BACKUP" ]; then
	echo "No successful backups found."
	exit 1
fi

echo "Latest successful backup: $LATEST_BACKUP"
velero restore create --from-backup $LATEST_BACKUP --wait --include-resources persistentvolumeclaims,persistentvolumes,volumesnapshots.snapshot.storage.k8s.io,volumesnapshotcontents.snapshot.storage.k8s.io,volumesnapshotclasses.snapshot.storage.k8s.io
