# Google Compute Project Metadata for SSH key
resource "google_compute_project_metadata" "ssh_keys" {
  metadata = {
    ssh_keys = var.ssh_key
  }
}