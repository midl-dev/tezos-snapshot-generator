#!/bin/sh

set -ex

bin_dir="/usr/local/bin"

data_dir="/var/run/tezos"
node_dir="$data_dir/node"
client_dir="$data_dir/client"

printf "Writing custom configuration\n"

rm -rvf ${node_dir}/data/config.json
mkdir -p ${node_dir}/data
cat << EOF > ${node_dir}/data/config.json
{ "data-dir": "/var/run/tezos/node/data",
  "network": "$TEZOS_NETWORK",
  "rpc": { "listen-addrs": [ ":8732", "0.0.0.0:8732" ],
      "acl":
        [ { "address": ":8732", "blacklist": [] } ]
    },
  "shell": { "chain_validator": { "bootstrap_threshold": 1 },
             "history_mode": "full" } }
EOF

cat ${node_dir}/data/config.json
