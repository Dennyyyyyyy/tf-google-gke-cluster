provider "google" {
  # Configuration options
  credentials = file("/home/workdlout/tf_flux/sa_api.json")
  project = var.GOOGLE_PROJECT
  region  = var.GOOGLE_REGION
}

resource "google_container_cluster" "demo" {
  name                     = "demo"
  location                 = var.GOOGLE_REGION
  cluster_ipv4_cidr        = "10.48.0.0/14"
  initial_node_count       = 1
  remove_default_node_pool = true

    workload_identity_config {
    workload_pool = "${var.GOOGLE_PROJECT}.svc.id.goog"
  }
  node_config {
        service_account = "sv-keapi@k8s-k3s-405517.iam.gserviceaccount.com"
        workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}

resource "google_container_node_pool" "demo" {
  name       = var.GKE_POOL_NAME
  project    = google_container_cluster.demo.project
  cluster    = google_container_cluster.demo.name
  location   = google_container_cluster.demo.location
  node_count = var.GKE_NUM_NODES

  node_config {
    service_account = "sv-keapi@k8s-k3s-405517.iam.gserviceaccount.com"
    machine_type = var.GKE_MACHINE_TYPE
  }
}

module "gke_auth" {
  depends_on = [
    google_container_cluster.demo
  ]
  source               = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  version              = ">= 24.0.0"
  project_id           = var.GOOGLE_PROJECT
  cluster_name         = google_container_cluster.demo.name
  location             = var.GOOGLE_REGION
}

resource "local_file" "kubeconfig" {
  content  = module.gke_auth.kubeconfig_raw
  filename = "${path.module}/kubeconfig"
  file_permission = "0400"
}
