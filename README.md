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

First, go to `terraform` folder:

```
cd terraform
```

Below is a list of variables you must set.

<!-- generate with  ~/go/bin/terraform-docs markdown table . -->

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| billing\_account | Google Cloud Billing account ID. | `string` | `""` | no |
| cluster\_ca\_certificate | kubernetes cluster certificate | `string` | `""` | no |
| cluster\_name | name of the kubernetes cluster | `string` | `""` | no |
| explorer\_subdomain | for block explorers such as tzkt or tzstats, non-mainnet networks are accessible through a subdomain such as delphi.tzkt.io. specify it here, with a dot. for exmaple 'delphi.' | `string` | `""` | no |
| firebase\_project | name of the firebase project for the snapshot website | `string` | `""` | no |
| firebase\_token | firebase token (secret) to publish to the xtz-shots website. Create with `firebase login:ci` | `string` | `""` | no |
| full\_snapshot\_url | The snapshot engine can also sync faster with a snapshot. Pass here the url of the snapshot of type full to download | `string` | `""` | no |
| kubernetes\_access\_token | Kubernetes access token for accessing pre-existing cluster | `string` | `""` | no |
| kubernetes\_endpoint | name of the kubernetes endpoint | `string` | `""` | no |
| kubernetes\_name\_prefix | kubernetes name prefix to prepend to all resources (should be short, like xtz) | `string` | `"xtz"` | no |
| kubernetes\_namespace | kubernetes namespace to deploy the resource into | `string` | `"tzshots"` | no |
| kubernetes\_pool\_name | when kubernetes cluster has several node pools, specify which ones to deploy the baking setup into. only effective when deploying on an external cluster with terraform\_no\_cluster\_create | `string` | `"blockchain-pool"` | no |
| node\_locations | Zones in which to create the nodes | `list` | <pre>[<br>  "us-central1-b",<br>  "us-central1-f"<br>]</pre> | no |
| org\_id | Google Cloud Organization ID. | `string` | `""` | no |
| project | Google Cloud Project ID. A default Google Cloud project should have been created when you activated your account. Verify its ID with `gcloud projects list`. If not given, Terraform will generate a new project. | `string` | `""` | no |
| region | Region in which to create the cluster, or region where the cluster exists. | `string` | `"us-central1"` | no |
| snapshot\_cron\_schedule | the schedule on which to generate snapshots, in cron format | `string` | `"7 13 * * *"` | no |
| terraform\_service\_account\_credentials | path to terraform service account file, created following the instructions in https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform | `string` | `"~/.config/gcloud/application_default_credentials.json"` | no |
| tezos\_network | The tezos network i.e. mainnet, carthagenet... | `string` | `"mainnet"` | no |
| tezos\_version | The desired tezos software branch. It will pull a container with this tag | `string` | `"latest-release"` | no |


#### Note Firebase

Note: I tried to make the firebase project and the token automatically with terraform, but there was a bug. See `terraform/firebase.tf`

For now, the terraform project must be created separately, and a CI token must be created with the `firebase login:ci` command.

Then pass the project id as `firebase_project` and the token as `firebase_token`.

### Deploy

1. Run the following:

```
terraform init
terraform plan -out plan.out
terraform apply plan.out
```

This will take time as it will:
* create a Google Cloud project
* create a Kubernetes cluster
* build the necessary containers
* push the kubernetes configuration, which will spin up a node a start synchronization

In case of error, run the `plan` and `apply` steps again:

```
terraform plan -out plan.out
terraform apply plan.out
```

### Connect to the cluster

Once the command returns, you can verify that the pods are up by running:

```
kubectl get pods
```

## Wrapping up

To delete everything and terminate all the charges, issue the command:

```
terraform destroy
```

Alternatively, go to the GCP console and delete the project.
