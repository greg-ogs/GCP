# To run use docker run --rm -it -v ./terraform/base:/terraform gregogs/terraform:base apply \
# -var="project_id=$(gcloud config get-value project)" -var="ssh_key=greg-ogs:$(cat /home/greg-ogs/.ssh/id_rsa.pub)"

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project     = data.terraform_remote_state.base.outputs.project_metadata_id
  credentials = file("/terraform/.gcp/credentials.json")
  region      = "us-central1"
}

