#!/bin/bash -x
# workload identity allows this to work
gcloud container clusters get-credentials blockchain --region us-central1

cd /mnt/snapshot-cache-volume

find

echo "now rsyncing snapshots to $WEBSITE_BUCKET_URL"
gsutil -m rsync /mnt/snapshot-cache-volume $WEBSITE_BUCKET_URL
