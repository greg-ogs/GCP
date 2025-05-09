# Startup script to get instance metadata and send to cloud storage
locals {
  startup_script_path = "/terraform/start-up.sh"
  startup_script_content = file(local.startup_script_path)
}

# Health check for the load balancer
resource "google_compute_health_check" "http_health_check" {
  name               = "http-health-check"
  timeout_sec        = 5
  check_interval_sec = 30

  http_health_check {
    port         = 80
    request_path = "/"
  }
}

# Instance Template for us-central1 region
resource "google_compute_instance_template" "instance_template_central" {
  name        = "epam-tf-us-central1"
  description = "Instance template for us-central1 region"

  machine_type = "f1-micro"

  disk {
    source_image = "debian-12"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = data.terraform_remote_state.base.outputs.subnetworks_ids[0]
    access_config {
      // Ephemeral IP
    }
  }

  # Fetch SSH keys from project metadata and startup script
  metadata = {
    ssh-keys = "${data.terraform_remote_state.base.outputs.ssh_key}"
    startup-script = local.startup_script_content
  }

  service_account {
    email  = data.terraform_remote_state.base.outputs.service_account_email
    scopes = ["storage-full"]
  }

  tags = ["web-instances", "http-server", "ssh-server"]
}

# Instance Template for us-east1 region
resource "google_compute_instance_template" "instance_template_east" {
  name        = "epam-tf-us-east1"
  description = "Instance template for us-east1 region"

  machine_type = "f1-micro"

  disk {
    source_image = "debian-12"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = data.terraform_remote_state.base.outputs.subnetworks_ids[1]
    access_config {
      // Ephemeral IP
    }
  }

  # Fetch SSH keys from project metadata and startup script
  metadata = {
    ssh-keys = "${data.terraform_remote_state.base.outputs.ssh_key}"
    startup-script = local.startup_script_content
  }

  service_account {
    email  = data.terraform_remote_state.base.outputs.service_account_email
    scopes = ["storage-full"]
  }

  tags = ["web-instances", "http-server", "ssh-server"]
}



# Region Instance Group Manager for us-central1
resource "google_compute_region_instance_group_manager" "instance_group_central" {
  name               = "epam-gcp-tf-us-central1"
  base_instance_name = "web-central"
  region             = "us-central1"
  target_size        = 1

  version {
    instance_template = google_compute_instance_template.instance_template_central.id
  }

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.http_health_check.id
    initial_delay_sec = 300
  }
}

# Region Instance Group Manager for us-east1
resource "google_compute_region_instance_group_manager" "instance_group_east" {
  name               = "epam-gcp-tf-us-east1"
  base_instance_name = "web-east"
  region             = "us-east1"
  target_size        = 1

  version {
    instance_template = google_compute_instance_template.instance_template_east.id
  }

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.http_health_check.id
    initial_delay_sec = 300
  }
}

# # Global HTTP Load Balancer components
#
# # Backend services
# resource "google_compute_backend_service" "backend_service" {
#   name                  = "web-backend-service"
#   protocol              = "HTTP"
#   port_name             = "http"
#   timeout_sec           = 30
#   health_checks         = [google_compute_health_check.http_health_check.id]
#   load_balancing_scheme = "EXTERNAL"
#
#   backend {
#     group = google_compute_region_instance_group_manager.instance_group_central.instance_group
#   }
#
#   backend {
#     group = google_compute_region_instance_group_manager.instance_group_east.instance_group
#   }
# }
#
# # URL map
# resource "google_compute_url_map" "url_map" {
#   name            = "web-url-map"
#   default_service = google_compute_backend_service.backend_service.id
# }
#
# # HTTP proxy
# resource "google_compute_target_http_proxy" "http_proxy" {
#   name    = "web-http-proxy"
#   url_map = google_compute_url_map.url_map.id
# }
#
# # Global forwarding rule
# resource "google_compute_global_forwarding_rule" "forwarding_rule" {
#   name                  = "web-forwarding-rule"
#   target                = google_compute_target_http_proxy.http_proxy.id
#   port_range            = "80"
#   load_balancing_scheme = "EXTERNAL"
# }
