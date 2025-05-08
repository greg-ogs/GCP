# Create a service account
resource "google_service_account" "epam_gcp_service_account" {
  account_id   = "${var.name}-${var.surname}-01-account"
  display_name = "${var.name} ${var.surname} Service Account"
  description  = "Service account for EPAM GCP"
}

# Assign the Storage Object Creator role to the service account
resource "google_project_iam_binding" "storage_object_creator_binding" {
  project = var.project_id
  role    = "roles/storage.objectCreator"

  members = [
    "serviceAccount:${google_service_account.epam_gcp_service_account.email}",
  ]
}
