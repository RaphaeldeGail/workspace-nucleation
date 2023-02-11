variable "billing_account" {
  type        = string
  description = "The ID of the billing account used for the workspace."
  nullable    = false
}

variable "organization" {
  type        = string
  description = "Name of the organization hosting the workspace."
  nullable    = true
  default     = null
}

variable "folder" {
  type        = string
  description = "The ID of the parent folder."
  nullable    = true
  default     = null
}

variable "region" {
  type        = string
  description = "Geographical *region* for Google Cloud Platform."
  nullable    = false
}

variable "service_accounts" {
  type = map(object({
    description = string
    roles       = list(string)
  }))
  description = "List of service accounts along with their privileges. Only underscore, digits and lowercase letters are allowed for the key."
  nullable    = false
}

variable "name" {
  type        = string
  default     = "root"
  description = "Name of the new workspace."
  validation {
    # regex(...) fails if it cannot find a match
    condition     = can(regex("^[a-z]*$", var.name))
    error_message = "Only lowercase letters are allowed in the workspace name."
  }
  nullable = false
}

variable "maj_version" {
  type        = number
  default     = 0
  description = "Major version of the new workspace. Defaults to 0."
  validation {
    # regex(...) fails if it cannot find a match
    condition     = var.maj_version - floor(var.maj_version) == 0
    error_message = "Major version can only be an integer."
  }
  nullable = false
}