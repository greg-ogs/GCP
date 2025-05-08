# Output the created resources
output "vpc_name" {
  value = google_compute_network.vpc_network.name
}

output "vpc_id" {
  value = google_compute_network.vpc_network.id
}

output "subnetwork_central_name" {
  value = google_compute_subnetwork.subnetwork_central.name
}

output "subnetwork_east_name" {
  value = google_compute_subnetwork.subnetwork_east.name
}

output "subnetworks_ids" {
  value = toset([
    google_compute_subnetwork.subnetwork_central.id,
    google_compute_subnetwork.subnetwork_east.id
  ])
}

# Output the bucket name
output "bucket_name" {
  value = google_storage_bucket.epam_lab_bucket.name
}

output "bucket_id" {
  value = google_storage_bucket.epam_lab_bucket.id
}

# Output the project metadata id
output "project_metadata_id" {
  value = google_compute_project_metadata.ssh_keys.id
}

# Output the service account email for reference
output "service_account_email" {
  value = google_service_account.epam_gcp_service_account.email
}
