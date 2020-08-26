# Tezos snapshot generator

This is a self-container Kuberneted cluster to generate Tezos snapshots, deployable with just one command.

When running your own Tezos baking operations, it is essential to be able to quickly recover from a disaster. Snapshots help you to get a node fully bootstrapped sooner.

These snapshots are available at [XTZ-shots](https://xtz-shots.io), but you may want to deploy the entire snapshot generation engine yourself, so your disaster recovery plan does not depend on any third-party services.

## Features

* runs a Kubernetes full node with "full" storage mode
* leverages the Kubernetes Persistent Volume Snapshot feature: takes a snapshot of the storage at filesystem level before generating the Tezos snapshot
* runs the snapshot generation job on a configurable cron schedule, for both "full" and "rolling" modes
* generates markdown metadata and a Jekyll static webpage describing the snapshots
* deploys snapshot and static webpage to Firebase
* supports any Tezos network (mainnet, testnets...)

## How to deploy

### Prerequisites

1. Download and install [Terraform](https://terraform.io)

1. Download, install, and configure the [Google Cloud SDK](https://cloud.google.com/sdk/).

1. Install the [kubernetes
   CLI](https://kubernetes.io/docs/tasks/tools/install-kubectl/) (aka
   `kubectl`)


### Authentication

Using your Google account, active your Google Cloud access.

Login to gcloud using `gcloud auth login`

Set up [Google Default Application Credentials](https://cloud.google.com/docs/authentication/production) by issuing the command:

```
gcloud auth application-default login
```

### Populate terraform variables

All custom values unique to your deployment are set as terraform variables. You must populate these variables manually before deploying the setup.

A simple way is to populate a file called `terraform.tfvars`.

NOTE: `terraform.tfvars` is not recommended for a production deployment. See [production hardening](docs/production-hardening.md).

First, go to `terraform` folder:

```
cd terraform
```

Below is a list of variables you must set.

### Google Cloud project

A default Google Cloud project should have been created when you activated your account. Verify its ID with `gcloud projects list`. You may also create a dedicated project to deploy the cluster.

Set the project id in the `project` terraform variable.

### Tezos network

Set the `tezos_network` variable to the network to use (`mainnet`, `carthagenet`, etc)

