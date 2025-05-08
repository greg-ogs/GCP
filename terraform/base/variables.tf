
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