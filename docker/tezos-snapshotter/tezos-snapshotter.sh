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
# Page settings
layout: default
keywords:
comments: false

# Hero section
title: Mainnet snapshots
description: 

# Author box
author:
    title: MIDL.dev
    title_url: 'https://midl.dev/'
    external_url: true
    description: MIDL.dev is a staking-as-a-service company

# Micro navigation
micro_nav: true

# Page navigation
page_nav:
    home:
        content: Previous page
        url: 'https://xtz-shots.io/index.html'
---

## Tezos snapshot for ${TEZOS_NETWORK}

Block height: $BLOCK_HEIGHT

Block hash: \`${BLOCK_HASH}\` - [Verify on TzStats](https://tzstats.com/${BLOCK_HASH}) - [Verify on TzKT](https://tzkt.io/${BLOCK_HASH})

Block timestamp: $BLOCK_TIMESTAMP

## Rolling snapshot

[Rolling Snapshot](${snapshot_name}.rolling)

### How to use

Issue the following commands:

```
wget https://${TEZOS_NETWORK}.xtz-shots.io/${snapshot_name}.rolling
tezos-node snapshot import ${snapshot_name}.rolling --block ${BLOCK_HASH}
```

Or simply use the permalink:
```
wget https://${TEZOS_NETWORK}.xtz-shots.io/rolling -O tezos-mainnet.rolling
tezos-node snapshot import tezos-mainnet.rolling
```

## Full snapshot

[Full Snapshot](${snapshot_name}.full)

### How to use

Issue the following commands:

```
wget https://${TEZOS_NETWORK}.xtz-shots.io/${snapshot_name}.full
tezos-node snapshot import ${snapshot_name}.full --block ${BLOCK_HASH}
```

Or simply use the permalink:
```
wget https://${TEZOS_NETWORK}.xtz-shots.io/full -O tezos-mainnet.full
tezos-node snapshot import tezos-mainnet.full
```


More details in [Tezos documentation](https://tezos.gitlab.io/user/snapshots.html).


EOF

chmod -R 777 /mnt/snapshot-cache-volume/firebase-files
