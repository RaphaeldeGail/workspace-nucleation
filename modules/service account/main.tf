/**
 * # Service Account
 * 
 * This module creates a service account as an object.
 * 
 * Organization roles are then applied for the account.
 */

terraform {
  required_version = "~> 1.1.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.5.0"
    }
  }
}

locals {
  lowercase_name = lower(replace(trimspace(var.full_name), "_", "-"))
  display_name   = title(replace(trimspace(var.full_name), "_", " "))
}

resource "google_service_account" "service_account" {
  account_id   = local.lowercase_name
  display_name = local.display_name
  description  = var.description
  project      = var.project_id
}

resource "google_service_account_key" "service_account_key" {
  count = var.bucket_name != null ? 1 : 0

  service_account_id = google_service_account.service_account.name
}

resource "google_storage_bucket_object" "service_account_key_backup" {
  count = var.bucket_name != null ? 1 : 0

  name         = "accounts/${local.lowercase_name}.json"
  content      = base64decode(google_service_account_key.service_account_key[0].private_key)
  content_type = "application/json; charset=utf-8"
  bucket       = var.bucket_name
}

resource "google_organization_iam_member" "organization_role" {
  for_each = toset(var.roles)

  org_id = var.org_id
  role   = join("/", ["roles", each.value])
  member = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_storage_bucket_iam_member" "bucket_editor" {
  count = var.bucket_name != null ? 1 : 0

  bucket = var.bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.service_account.email}"
}