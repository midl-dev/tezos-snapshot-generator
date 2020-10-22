#!/bin/bash

set -e
set -x

# workload identity allows this to work
gcloud container clusters get-credentials blockchain --region us-central1

# first, delete old versions of pvc and snapshot that may still be present
if kubectl get pvc ${KUBERNETES_NAME_PREFIX}-tezos-node-pv-snapshot-provision -n ${KUBERNETES_NAMESPACE} --template {{.metadata.name}}
then
    kubectl delete --wait=false pvc  ${KUBERNETES_NAME_PREFIX}-tezos-node-pv-snapshot-provision
    # force unattach
    kubectl patch pvc  ${KUBERNETES_NAME_PREFIX}-tezos-node-pv-snapshot-provision  -p '{"metadata":{"finalizers": []}}' --type=merge -n ${KUBERNETES_NAMESPACE} || true
fi
if kubectl get volumesnapshot ${KUBERNETES_NAME_PREFIX}-tezos-node-pv-snapshot -n ${KUBERNETES_NAMESPACE} --template {{.metadata.name}}
then
    kubectl delete volumesnapshot ${KUBERNETES_NAME_PREFIX}-tezos-node-pv-snapshot -n ${KUBERNETES_NAMESPACE}
fi

# delete old tezosSnapshotter jobs - in this case, we want them preserved after one job because they contain logs that may be of interest.
# But GKE does not support ttl for simple jobs (not cronjobs) so we delete old ones here.
jobs_to_delete=$(kubectl get jobs -n ${KUBERNETES_NAMESPACE} --selector=app=tezos-snapshotter -o=jsonpath='{.items[?(@.status.succeeded==1)].metadata.name}')
if [ "$(echo $jobs_to_delete | wc -w)" != "0" ]; then
    kubectl delete job $jobs_to_delete -n ${KUBERNETES_NAMESPACE}
fi

# fetch the most recent block hash. This will be the snapshot.
export BLOCK_HASH=$(curl http://${KUBERNETES_NAME_PREFIX}-tezos-public-node:8732/monitor/bootstrapped | jq -r '.block')
export BLOCK_HEIGHT=$(curl http://${KUBERNETES_NAME_PREFIX}-tezos-public-node:8732/chains/main/blocks/head | jq -r '.header.level' )
export BLOCK_TIMESTAMP=$(curl http://${KUBERNETES_NAME_PREFIX}-tezos-public-node:8732/chains/main/blocks/head | jq -r '.header.timestamp' )

cd /snapshot-engine

cd volumeSnapshotter
envsubst < kustomization.yaml.tmpl > kustomization.yaml
envsubst < volumeSnapshotter.yaml.tmpl > volumeSnapshotter.yaml
kubectl apply -k .

while [ "$(kubectl get volumesnapshot ${KUBERNETES_NAME_PREFIX}-tezos-node-pv-snapshot -n ${KUBERNETES_NAMESPACE} --template={{.status.readyToUse}})" != "true" ]; do
    printf "Waiting for volume snapshot creation to complete\n"
    sleep 10
done

cd ..

cd volumeSnapshotMount
envsubst < kustomization.yaml.tmpl > kustomization.yaml
envsubst < volumeSnapshotMount.yaml.tmpl > volumeSnapshotMount.yaml
kubectl apply -k .
cd ..

cd tezosSnapshotter
envsubst < kustomization.yaml.tmpl > kustomization.yaml
envsubst < tezosSnapshotter.yaml.tmpl > tezosSnapshotter.yaml
envsubst < nodepool.yaml.tmpl > nodepool.yaml
kubectl apply -k .
cd ..

printf "wait for snapshot job to complete\n"
kubectl wait --for=condition=complete --timeout=5h job/${KUBERNETES_NAME_PREFIX}-tezos-snapshotter-${BLOCK_HEIGHT} -n ${KUBERNETES_NAMESPACE}

sleep 10


# clean up pv and snapshots. do not clean up job as its logs must be preserved.
cd volumeSnapshotMount
kubectl delete --wait=false -k .
# force unattach - if we don't do that, sometimes the pvc remains protected and does not get deleted
# https://stackoverflow.com/questions/51358856/kubernetes-cant-delete-persistentvolumeclaim-pvc
kubectl patch pvc  ${KUBERNETES_NAME_PREFIX}-tezos-node-pv-snapshot-provision  -p '{"metadata":{"finalizers": []}}' --type=merge -n ${KUBERNETES_NAMESPACE} || true
cd ..
cd volumeSnapshotter
# it takes a long time to delete. do not wait for this.
kubectl delete --wait=false -k .
cd ..

kubectl get configmap -n ${KUBERNETES_NAMESPACE} -n ${KUBERNETES_NAMESPACE} --template {{.metadata.name}} | grep ${KUBERNETES_NAME_PREFIX}-tezsos-snapshotter-configmap | while read cm; do
  kubectl delete configmap $cm -n ${KUBERNETES_NAMESPACE} 
done
