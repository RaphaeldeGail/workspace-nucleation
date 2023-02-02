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