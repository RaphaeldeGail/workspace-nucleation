variable "full_name" {
  type        = string
  description = "Name of the service account. May only contain underscore, digits and lowercase letters."
  nullable    = false
  validation {
    # regex(...) fails if it cannot find a match
    condition     = can(regex("^[a-z0-9_]*$", var.full_name))
    error_message = "Only underscore, digits and lowercase letters are allowed in the service account name."
  }
}

variable "project_id" {
  type        = string
  description = "ID of the project hosting the service account."
  nullable    = false
}

variable "description" {
  type        = string
  description = "Optional description of the service account."
  nullable    = true
}

variable "bucket_name" {
  type        = string
  description = "Name of the bucket for service account key backup. If a non-null value is given, a private key for the service account will be created and upload to the bucket."
  default     = null
  nullable    = true
}

variable "roles" {
  type        = list(string)
  description = "A list of organization-scoped roles for the service account."
  nullable    = false
}

variable "org_id" {
  type        = string
  description = "The organization ID as a string."
  nullable    = false
}