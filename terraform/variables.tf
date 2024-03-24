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
  description = "Name, or domain, of the organization hosting the workspace."
  nullable    = false
}

variable "tfe_organization" {
  type        = string
  description = "Name of the Terraform Cloud organization hosting the workspaces."
  nullable    = false
}

variable "workspaces_folder" {
  type        = string
  description = "The ID of the \"Workspaces\" folder that contains all subsequent workspaces."
  nullable    = false
}

variable "workspaces_tag_key" {
  type        = string
  description = "The ID of \"workspace\" tag key."
  nullable    = false
}

variable "region" {
  type        = string
  description = "Geographical *region* for Google Cloud Platform."
  nullable    = false
}

variable "customer_directory" {
  type        = string
  description = "The ID of the Google Cloud Identity directory."
  nullable    = false
}

variable "admin_group" {
  type        = string
  description = "Email for administrators group."
}

variable "policy_group" {
  type        = string
  description = "Email for policy administrators group."
}

variable "finops_group" {
  type        = string
  description = "Email for finops group."
}

variable "budget_allowed" {
  type        = number
  description = "The monthly amount allowed for the workspace. Must be an integer."
  nullable    = false
}

variable "billing_email" {
  type        = string
  description = "The name of the Google group with billing usage authorization."
  nullable    = false
}

variable "organization_identities" {
  type        = string
  description = "The name of the workload identity pool for the oragnization."
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

  labels = { workspace = tostring(local.name) }
}