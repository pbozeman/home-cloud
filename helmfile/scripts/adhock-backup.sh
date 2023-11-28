#!/bin/sh

current_time=$(date +"%Y%m%d%H%M%S")
backup_name="adhoc-${current_time}"
velero backup create $backup_name
