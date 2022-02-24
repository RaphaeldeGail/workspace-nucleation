/**
 * # Service Account
 * 
 * This module creates a service account as an object.
 * 
 * A service account authentication key is also bound and pushed to a google storage bucket if a **bucket_name** is given.
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
  count              = var.bucket_name != null ? 1 : 0
  service_account_id = google_service_account.service_account.name
}

resource "google_storage_bucket_object" "service_account_key_backup" {
  count        = var.bucket_name != null ? 1 : 0
  name         = "accounts/${local.lowercase_name}.json"
  content      = base64decode(google_service_account_key.service_account_key[0].private_key)
  content_type = "application/json; charset=utf-8"
  bucket       = var.bucket_name
}