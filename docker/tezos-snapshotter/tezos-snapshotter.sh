#!/bin/sh

set -ex

bin_dir="/usr/local/bin"

data_dir="/var/run/tezos"
node_dir="$data_dir/node"
client_dir="$data_dir/client"

snapshot_name="tezos-${TEZOS_NETWORK}-${BLOCK_HEIGHT}"
/usr/local/bin/tezos-node snapshot export \
    --data-dir $node_dir/data \
    --block ${BLOCK_HASH} \
    --rolling \
    /mnt/snapshot-cache-volume/${snapshot_name}.rolling
/usr/local/bin/tezos-node snapshot export \
    --data-dir $node_dir/data \
    --block ${BLOCK_HASH} \
    /mnt/snapshot-cache-volume/${snapshot_name}.full

mkdir -p /mnt/snapshot-cache-volume/firebase-files/
cat << EOF > /mnt/snapshot-cache-volume/firebase-files/index.md
---
layout: default
---

## Tezos snapshot for ${TEZOS_NETWORK}

Block height: $BLOCK_HEIGHT

Block hash: \`${BLOCK_HASH}\` - [Verify on TzStats](https://tzstats.com/${BLOCK_HASH}) - [Verify on TzKT](https://tzkt.io/${BLOCK_HASH})

Block timestamp: $BLOCK_TIMESTAMP

## Rolling snapshot

[Rolling Snapshot](${snapshot_name}.rolling)

## Full snapshot

[Full Snapshot](${snapshot_name}.full)


EOF

chmod -R 777 /mnt/snapshot-cache-volume/firebase-files
