variable "billing_account" {
  type        = string
  description = "Name of the billing account used for the workspace. \"Billing account User\" permissions are required to execute module."
  nullable    = false
}

variable "organization" {
  type        = string
  description = "Name of the organization hosting the workspace."
  nullable    = false
}

variable "location" {
  type        = string
  description = "Geographical *location* for Google Cloud Platform."
  nullable    = false
}

variable "region" {
  type        = string
  description = "Geographical *region* for Google Cloud Platform."
  nullable    = false
}

variable "service_accounts" {
  type = map(object({
    description = string
    role        = string
  }))
  description = "List of service accounts along with their privileges. Only underscore, digits and lowercase letters are allowed for the key."
  nullable    = false
}