#!/bin/bash -x
# workload identity allows this to work
gcloud container clusters get-credentials blockchain --region us-central1

cd /mnt/snapshot-cache-volume

find

echo "now rsyncing snapshots to $WEBSITE_BUCKET_URL"
gsutil -m rsync /mnt/snapshot-cache-volume $WEBSITE_BUCKET_URL

# delete older versions of objects - keep only two
bucket_content=$(gsutil ls $WEBSITE_BUCKET_URL)

echo "$bucket_content" | while read line; do
  # extract all the block heights that we are storing
  # sort -V will deal with increasing number size such as going from block 99xxx to 100xxx
  sed -e "s/.*\/\([^/]*\)$s/\1/g"| tr '\n' ' ' | sed -e 's/[^0-9]/ /g' -e 's/^ *//g' -e 's/ *$//g' | tr -s ' ' | sed 's/ /\n/g'
done | uniq | sort -V | head -n -2 | while read block_height_to_delete; do
  echo "$bucket_content" | grep $block_height_to_delete | while read url_to_delete; do
    gsutil rm $url_to_delete
  done
done
