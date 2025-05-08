# To run use docker run --rm -it -v ./terraform/base:/terraform gregogs/terraform:base <command> -var="project_id=$(gcloud config get-value project)"

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}


provider "google" {
  project     = var.project_id
  credentials = file("/terraform/.gcp/credentials.json")
  region      = "us-central1"
}

# Variables for student name and surname
variable "student_name" {
  description = "Student's first name"
  type        = string
  default     = "greg"  # Replace with your actual name
}

variable "student_surname" {
  description = "Student's surname"
  type        = string
  default     = "greg-ogs"  # Replace with your actual surname
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

# Output the created resources
output "vpc_name" {
  value = google_compute_network.vpc_network.name
}

output "subnetwork_central_name" {
  value = google_compute_subnetwork.subnetwork_central.name
}

output "subnetwork_east_name" {
  value = google_compute_subnetwork.subnetwork_east.name
}
