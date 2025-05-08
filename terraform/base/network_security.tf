# Firewall rules for the VPC network

# SSH inbound rule - allows SSH access from safe IP ranges
resource "google_compute_firewall" "ssh_access" {
  name        = "ssh-access"
  network     = google_compute_network.vpc_network.id
  description = "Allows SSH access from safe IP ranges"
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  
  source_ranges = var.safe_ip_ranges
  target_tags   = ["ssh-server"]
}

# HTTP inbound rule - allows HTTP access from LoadBalancer and safe IP ranges
resource "google_compute_firewall" "http_access" {
  name        = "http-access"
  network     = google_compute_network.vpc_network.id
  description = "Allows HTTP access from LoadBalancer and safe IP ranges"
  
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  
  source_ranges = concat(var.loadbalancer_ip_ranges, var.safe_ip_ranges)
  target_tags   = ["http-server"]
}
