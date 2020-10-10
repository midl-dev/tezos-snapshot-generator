#!/usr/bin/python3

import json
import os

# Creates a firebase.json with the appropriate redirects.

firebase_conf = json.loads(""" {
  "hosting": {
    "public": "_site",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ]
  }
}
""")

firebase_conf["hosting"]["redirects"] = [ { "source": ":block.rolling", "type": 301, "destination": "https://storage.googleapis.com/%s/:block.rolling" % os.environ['WEBSITE_BUCKET_URL'].replace("gs://", "") },
        { "source": ":block.full", "type": 301, "destination": "https://storage.googleapis.com/%s/:block.full" % os.environ['WEBSITE_BUCKET_URL'].replace("gs://", "") },
        { "source": "rolling", "type": 301, "destination": "https://storage.googleapis.com/%s/tezos-%s-%s.rolling" % (os.environ['WEBSITE_BUCKET_URL'].replace("gs://", ""), os.environ['TEZOS_NETWORK'], os.environ['BLOCK_HEIGHT']) },
        { "source": "full", "type": 301, "destination": "https://storage.googleapis.com/%s/tezos-%s-%s.full" % (os.environ['WEBSITE_BUCKET_URL'].replace("gs://",""), os.environ['TEZOS_NETWORK'], os.environ['BLOCK_HEIGHT']) } ]

print(json.dumps(firebase_conf, indent=4))
