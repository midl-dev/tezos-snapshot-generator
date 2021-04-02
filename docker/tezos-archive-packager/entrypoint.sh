#!/bin/sh

set -ex

snapshot_name="tezos-${TEZOS_NETWORK}-${BLOCK_HEIGHT}-archive.7z"
ls /run/tezos/node/data

rm -rvf /run/tezos/node/data/*.json
rm -rvf /run/tezos/node/data/lock

7z a /mnt/snapshot-cache-volume/${snapshot_name} /run/tezos/node/data/*

snapshot_size=$(du -h /mnt/snapshot-cache-volume/${snapshot_name} | cut -f1)
cd /mnt/snapshot-cache-volume
sha256sum ${snapshot_name} > /mnt/snapshot-cache-volume/${snapshot_name}.sha256

mkdir -p /mnt/snapshot-cache-volume/firebase-files/
cat << EOF > /mnt/snapshot-cache-volume/firebase-files/index.md
---
# Page settings
layout: snapshot
keywords:
comments: false

# Hero section
title: Tezos Archive node filesystem dump for ${TEZOS_NETWORK}
description: 

# Author box
author:
    title: Brought to you by MIDL.dev
    title_url: 'https://midl.dev/tezos-suite'
    external_url: true
    description: A proof-of-stake infrastructure company. We help you bake your tez. <a href="https://MIDL.dev/tezos-suite" target="_blank">Learn more</a>.

# Micro navigation
micro_nav: true

# Page navigation
page_nav:
    home:
        content: Previous page
        url: 'https://xtz-shots.io/index.html'
---

# Tezos archive backup for ${TEZOS_NETWORK}

Block height: $BLOCK_HEIGHT

Block hash: \`${BLOCK_HASH}\`

[Verify on TzStats](https://${EXPLORER_SUBDOMAIN}tzstats.com/${BLOCK_HASH}){:target="_blank"} - [Verify on TzKT](https://${EXPLORER_SUBDOMAIN}tzkt.io/${BLOCK_HASH}){:target="_blank"}

Block timestamp: $BLOCK_TIMESTAMP

Archive size: ${snapshot_size}

[Download Archive](${snapshot_name})

## How to use

\`\`\`
wget https://${TEZOS_NETWORK}-archive.xtz-shots.io/${snapshot_name}
7z x ${snapshot_name} -o~/.tezos-node/data
rm -v ${snapshot_name}
\`\`\`

Or simply use the permalink:
\`\`\`
wget https://${TEZOS_NETWORK}-archive.xtz-shots.io/archive -O tezos-${TEZOS_NETWORK}-archive.7z
7z x ${TEZOS_NETWORK}-archive.7z -o~/.tezos-node/data
rm -v ${TEZOS_NETWORK}-archive.7z
\`\`\`

### More details

[About xtz-shots.io](https://xtz-shots.io/getting-started/).

[Tezos documentation](https://tezos.gitlab.io/user/snapshots.html){:target="_blank"}.
EOF

echo "**** DEBUG OUTPUT OF index.md *****"
cat /mnt/snapshot-cache-volume/firebase-files/index.md
echo "**** end debug ****"

chmod -R 777 /mnt/snapshot-cache-volume/firebase-files
