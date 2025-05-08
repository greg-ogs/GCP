
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