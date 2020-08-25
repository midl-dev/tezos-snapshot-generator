## Tezos snapshot generator

This is a self-container Kubernetes cluster to generate Tezos snapshots.

I am going to use the k8s pv snapshot feature so I need a new cluster in version 1.17.

It will run a public node.

It will have a cronjob that applies a kubernetes manifest (convoluted, but no choice).

This manifest will:

* create a volume snapshot. see: https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/volume-snapshots
* launch a unique batch job to generate two snapshots from the volume and publish them somewhere
* delete the volume snapshot at the end
