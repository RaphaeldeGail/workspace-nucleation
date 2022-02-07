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

variable "role" {
  type        = string
  description = "role bound to the service account."
  nullable    = false
}

variable "bucket_name" {
  type        = string
  description = "Name of the bucket for service account key backup."
  nullable    = false
}