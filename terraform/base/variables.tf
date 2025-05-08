
variable "project_id" {
  description = "GCP Project ID"
  type        = string
  sensitive = true
}

variable "ssh_key" {
  description = "Provides custom public ssh key"
  sensitive = true
}

# Variables for student name and surname
variable "name" {
  description = "First name"
  type        = string
  default     = "greg"
}

variable "surname" {
  description = "Surname"
  type        = string
  default     = "ogs"
}

variable "safe_ip_ranges" {
  description = "Safe IP ranges for SSH and HTTP access (your IP or EPAM office IP ranges)"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Replace with actual safe IP ranges
}

variable "loadbalancer_ip_ranges" {
  description = "Google Cloud Health Checks IP ranges"
  type        = list(string)
  default     = ["130.211.0.0/22", "35.191.0.0/16"]
}
