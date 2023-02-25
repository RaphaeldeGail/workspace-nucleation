variable "credentials" {
  type        = string
  description = "The service account credentials."
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
  nullable    = true
  default     = null
}

variable "cloud_identity_id" {
  type        = string
  description = "The ID of the cloud identity resource."
  nullable    = false
}

variable "parent" {
  type        = string
  description = "The name of the parent workspace in the form of *{name}-v{version}*."
  nullable    = true
  default     = null

  validation {
    # regex(...) fails if it cannot find a match
    condition     = can(regex("^[a-z]*-v[0-9]$", var.parent)) || var.parent == null
    error_message = "The workspace parent name should be of the form *{name}-v{version}*."
  }
}

variable "region" {
  type        = string
  description = "Geographical *region* for Google Cloud Platform."
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

variable "team" {
  type = object({
    administrators        = list(string)
    policy_administrators = list(string)
    finops                = list(string)
  })
  description = "List of team members by roles, *administrator*, *policy_administrator* and *finops*."
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
  workspace_name = "${var.name}-v${var.maj_version}"
  index_length   = 16

  labels = var.parent == null ? { root = true } : { workspace = lower(var.name), version = tostring(var.maj_version) }
}