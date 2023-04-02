variable "project" {
  type        = string
  description = "The ID of the root project for the organization. Used to create workspaces."
  nullable    = false
}

variable "billing_account" {
  type        = string
  description = "The ID of the billing account used for the workspace."
  nullable    = false
}

variable "organization" {
  type        = string
  description = "Name of the organization hosting the workspace."
  nullable    = false
}

variable "region" {
  type        = string
  description = "Geographical *region* for Google Cloud Platform."
  nullable    = false
}

variable "team" {
  type = object({
    administrators        = list(string)
    policy_administrators = list(string)
    finops                = list(string)
  })
  description = "List of team members by roles, *administrator*, *policy_administrator* and *finops*."
  nullable    = false
}

variable "budget_allowed" {
  type        = number
  description = "The monthly amount allowed for the workspace. Must be an integer."
  nullable    = false
}

locals {
  apis = [
    "orgpolicy.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "serviceusage.googleapis.com",
    "iam.googleapis.com",
    "cloudidentity.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com",
    "iamcredentials.googleapis.com",
    "storage.googleapis.com",
    "cloudkms.googleapis.com"
  ]
  image_manager_permissions = [
    "compute.images.create",
    "compute.images.createTagBinding",
    "compute.images.delete",
    "compute.images.deleteTagBinding",
    "compute.images.deprecate",
    "compute.images.get",
    "compute.images.getFromFamily",
    "compute.images.getIamPolicy",
    "compute.images.list",
    "compute.images.listEffectiveTags",
    "compute.images.listTagBindings",
    "compute.images.setIamPolicy",
    "compute.images.setLabels",
    "compute.images.update",
    "compute.images.useReadOnly",
    "compute.globalOperations.get"
  ]
  index_length = 16
  name         = trimsuffix(terraform.workspace, "-workspace")

  labels = { workspace = lower(regex("^[a-z][a-z0-9]{1,9}[a-z]", local.name)), version = tostring(regex("[0-9]{2}$", local.name)) }
}