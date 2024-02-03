#!/bin/sh

current_time=$(date +"%Y%m%d%H%M%S")
backup_name="adhoc-home-${current_time}"
velero backup create $backup_name --wait --include-namespaces "monitoring,home-automation,media,paperless-ngx,immich,tandoor"
