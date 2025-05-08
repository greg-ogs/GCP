# To run use docker run --rm -it -v ./terraform/base:/terraform gregogs/terraform:base <command> -var="project_id=$(gcloud config get-value project)"

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project     = var.project_id
  credentials = file("/terraform/.gcp/credentials.json")
  region      = "us-central1"
}

# Create a VPC network
resource "google_compute_network" "vpc_network" {
  name                    = "${var.student_name}-${var.student_surname}-01-vpc"
  auto_create_subnetworks = false
  mtu                     = 1460
  routing_mode            = "REGIONAL"
}

# Create the central subnetwork
resource "google_compute_subnetwork" "subnetwork_central" {
  name          = "${var.student_name}-${var.student_surname}-01-subnetwork-central"
  ip_cidr_range = "10.10.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.id
}

# Create the east subnetwork
resource "google_compute_subnetwork" "subnetwork_east" {
  name          = "${var.student_name}-${var.student_surname}-01-subnetwork-east"
  ip_cidr_range = "10.10.3.0/24"
  region        = "us-east1"
  network       = google_compute_network.vpc_network.id
}

# Random string for unique bucket naming
resource "random_string" "my_numbers" {
  length  = 8
  special = false
  upper   = false
}

# Google Cloud Storage bucket with unique name
resource "google_storage_bucket" "epam_lab_bucket" {
  name          = "epam-tf-lab-${random_string.my_numbers.result}"
  location      = "us-central1"
  force_destroy = true
  uniform_bucket_level_access = true
}
