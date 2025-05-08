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

# Output the bucket name
output "bucket_name" {
  value = google_storage_bucket.epam_lab_bucket.name
}