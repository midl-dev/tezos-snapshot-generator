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

rolling_snapshot_size=$(du -h /mnt/snapshot-cache-volume/${snapshot_name}.rolling | cut -f1)
full_snapshot_size=$(du -h /mnt/snapshot-cache-volume/${snapshot_name}.full | cut -f1)

mkdir -p /mnt/snapshot-cache-volume/firebase-files/
cat << EOF > /mnt/snapshot-cache-volume/firebase-files/index.md
---
# Page settings
layout: snapshot
keywords:
comments: false

# Hero section
title: Tezos snapshots for ${TEZOS_NETWORK}
description: 

# Author box
author:
    title: Brought to you by MIDL.dev
    title_url: 'https://midl.dev/tezos-suite'
    external_url: true
    description: A proof-of-stake infrastructure company. We help you bake your XTZ. <a href="https://MIDL.dev/tezos-suite" target="_blank">Learn more</a>.

# Micro navigation
micro_nav: true

# Page navigation
page_nav:
    home:
        content: Previous page
        url: 'https://xtz-shots.io/index.html'
---

# Tezos snapshots for ${TEZOS_NETWORK}

Block height: $BLOCK_HEIGHT

Block hash: \`${BLOCK_HASH}\`

[Verify on TzStats](https://${EXPLORER_SUBDOMAIN}tzstats.com/${BLOCK_HASH}){:target="_blank"} - [Verify on TzKT](https://${EXPLORER_SUBDOMAIN}tzkt.io/${BLOCK_HASH}){:target="_blank"}

Block timestamp: $BLOCK_TIMESTAMP

## Rolling snapshot

[Download Rolling Snapshot](${snapshot_name}.rolling)

Size: ${rolling_snapshot_size}

## Full snapshot

[Download Full Snapshot](${snapshot_name}.full)

Size: ${full_snapshot_size}

## How to use

### Rolling

Issue the following commands:

\`\`\`
wget https://${TEZOS_NETWORK}.xtz-shots.io/${snapshot_name}.rolling
tezos-node snapshot import ${snapshot_name}.rolling --block ${BLOCK_HASH}
\`\`\`

Or simply use the permalink:
\`\`\`
wget https://${TEZOS_NETWORK}.xtz-shots.io/rolling -O tezos-${TEZOS_NETWORK}.rolling
tezos-node snapshot import tezos-${TEZOS_NETWORK}.rolling
\`\`\`

### Full

Issue the following commands:

\`\`\`
wget https://${TEZOS_NETWORK}.xtz-shots.io/${snapshot_name}.full
tezos-node snapshot import ${snapshot_name}.full --block ${BLOCK_HASH}
\`\`\`

Or simply use the permalink:
\`\`\`
wget https://${TEZOS_NETWORK}.xtz-shots.io/full -O tezos-${TEZOS_NETWORK}.full
tezos-node snapshot import tezos-${TEZOS_NETWORK}.full
\`\`\`


### More details

[About xtz-shots.io](https://xtz-shots.io/getting-started/).

[Tezos documentation](https://tezos.gitlab.io/user/snapshots.html){:target="_blank"}.


EOF

echo "**** DEBUG OUTPUT OF index.md *****"
cat /mnt/snapshot-cache-volume/firebase-files/index.md
echo "**** end debug ****"

chmod -R 777 /mnt/snapshot-cache-volume/firebase-files
