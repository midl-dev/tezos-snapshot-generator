locals {
  kubernetes_variables = { "project" : module.terraform-gke-blockchain.project,
       "tezos_version": var.tezos_version,
       "tezos_network": var.tezos_network,
       "kubernetes_namespace": var.kubernetes_namespace,
       "kubernetes_name_prefix": var.kubernetes_name_prefix,
       "firebase_project": var.firebase_project,
       "firebase_token": var.firebase_token,
       "explorer_subdomain": var.explorer_subdomain,
       #"firebase_project": google_firebase_web_app.snapshot_app.app_id,
       #"firebase_token": data.google_firebase_web_app_config.snapshot_app_config.api_key,
       "website_bucket_url": google_storage_bucket.snapshot_bucket.url,
       "kubernetes_pool_name": var.kubernetes_pool_name,
       "history_mode": var.archive_dumps == "true" ? "archive": "full",
       "full_snapshot_url": var.full_snapshot_url }
}

resource "google_service_account" "snapshot_engine_account" {
  account_id   = "${var.kubernetes_name_prefix}-snapshot-engine"
  display_name = "Snapshot engine for ${var.kubernetes_name_prefix}"
  project = module.terraform-gke-blockchain.project 
}

# based on workload identity docs
# https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity
resource "google_service_account_iam_binding" "snapshot_engine_account_binding" {
  service_account_id = google_service_account.snapshot_engine_account.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${module.terraform-gke-blockchain.project}.svc.id.goog[${var.kubernetes_namespace}/${var.kubernetes_name_prefix}-snapshot-engine]"
  ]
}

# the below to be able to run kubectl commands from within a kubectl pod (so we can create volume snapshots, and mount them, on a cron)
resource "google_project_iam_member" "snapshot_engine_account_k8s_permission" {
  role               = "roles/container.developer"
  project = module.terraform-gke-blockchain.project 

  member = "serviceAccount:${var.kubernetes_name_prefix}-snapshot-engine@${module.terraform-gke-blockchain.project}.iam.gserviceaccount.com"
}

resource "null_resource" "push_containers" {

  triggers = {
    host = md5(module.terraform-gke-blockchain.kubernetes_endpoint)
    cluster_ca_certificate = md5(
      module.terraform-gke-blockchain.cluster_ca_certificate,
    )
  }
  provisioner "local-exec" {
    interpreter = [ "/bin/bash", "-c" ]
    command = <<EOF
set -x

build_container () {
  set -x
  cd $1
  container=$(basename $1)
  cp Dockerfile.template Dockerfile
  sed -i "s/((tezos_version))/${var.tezos_version}/" Dockerfile
  cat << EOY > cloudbuild.yaml
steps:
- name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', "gcr.io/${module.terraform-gke-blockchain.project}/$container:${var.kubernetes_namespace}-latest", '.']
images: ["gcr.io/${module.terraform-gke-blockchain.project}/$container:${var.kubernetes_namespace}-latest"]
EOY
  gcloud builds submit --project ${module.terraform-gke-blockchain.project} --config cloudbuild.yaml .
  rm -v Dockerfile
  rm cloudbuild.yaml
}
export -f build_container
find ${path.module}/../docker -mindepth 1 -maxdepth 1 -type d -exec bash -c 'build_container "$0"' {} \; -printf '%f\n'
EOF
  }
}

resource "kubernetes_namespace" "tezos_snapshot_namespace" {
  metadata {
    name = var.kubernetes_namespace
  }
  depends_on = [ module.terraform-gke-blockchain ]
}

resource "null_resource" "apply" {
  provisioner "local-exec" {

    interpreter = [ "/bin/bash", "-c" ]
    command = <<EOF
set -e
set -x
gcloud container clusters get-credentials "${module.terraform-gke-blockchain.name}" --region="${module.terraform-gke-blockchain.location}" --project="${module.terraform-gke-blockchain.project}"

rm -rvf ${path.module}/k8s-${var.kubernetes_namespace}
mkdir -p ${path.module}/k8s-${var.kubernetes_namespace}
cp -rv ${path.module}/../k8s/*base* ${path.module}/k8s-${var.kubernetes_namespace}
cd ${abspath(path.module)}/k8s-${var.kubernetes_namespace}
cat <<EOK > kustomization.yaml
${templatefile("${path.module}/../k8s/kustomization.yaml.tmpl", local.kubernetes_variables)}
EOK

mkdir -pv tezos-public-node
cat <<EOK > tezos-public-node/kustomization.yaml
${templatefile("${path.module}/../k8s/tezos-public-node-tmpl/kustomization.yaml.tmpl", local.kubernetes_variables)}
EOK
cat <<EOPPVN > tezos-public-node/prefixedpvnode.yaml
${templatefile("${path.module}/../k8s/tezos-public-node-tmpl/prefixedpvnode.yaml.tmpl", {"kubernetes_name_prefix": var.kubernetes_name_prefix})}
EOPPVN
cat <<EONPN > tezos-public-node/nodepool.yaml
${templatefile("${path.module}/../k8s/tezos-public-node-tmpl/nodepool.yaml.tmpl", {"kubernetes_pool_name": var.kubernetes_pool_name})}
EONPN

mkdir -pv tezos-snapshot-engine
cat <<EOK > tezos-snapshot-engine/kustomization.yaml
${templatefile("${path.module}/../k8s/tezos-snapshot-engine-tmpl/kustomization.yaml.tmpl", local.kubernetes_variables)}
EOK
cat <<EONPN > tezos-snapshot-engine/nodepool.yaml
${templatefile("${path.module}/../k8s/tezos-snapshot-engine-tmpl/nodepool.yaml.tmpl", {"kubernetes_pool_name": var.kubernetes_pool_name})}
EONPN
cat <<EONPN > tezos-snapshot-engine/serviceaccountannotate.yaml
${templatefile("${path.module}/../k8s/tezos-snapshot-engine-tmpl/serviceaccountannotate.yaml.tmpl", local.kubernetes_variables)}
EONPN
cat <<EONPN > tezos-snapshot-engine/crontime.yaml
${templatefile("${path.module}/../k8s/tezos-snapshot-engine-tmpl/crontime.yaml.tmpl", {"snapshot_cron_schedule": var.snapshot_cron_schedule})}
EONPN
kubectl apply -k .
cd ${abspath(path.module)}
rm -rvf ${abspath(path.module)}/k8s-${var.kubernetes_namespace}
EOF

  }
  depends_on = [ null_resource.push_containers, kubernetes_namespace.tezos_snapshot_namespace ]
}

resource "random_id" "rnd_bucket" {
  byte_length = 4
}

resource "google_storage_bucket" "snapshot_bucket" {
  name     = "tezos-snapshot-bucket-${var.kubernetes_name_prefix}-${random_id.rnd_bucket.hex}"
  project = module.terraform-gke-blockchain.project

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
  force_destroy = true
}

resource "google_storage_bucket_iam_member" "member" {
  bucket = google_storage_bucket.snapshot_bucket.name
  role        = "roles/storage.objectAdmin"
  member      = "serviceAccount:${google_service_account.snapshot_engine_account.email}"
}

resource "google_storage_bucket_iam_member" "make_public" {
  bucket = google_storage_bucket.snapshot_bucket.name
  role        = "roles/storage.objectViewer"
  member      = "allUsers"
}
