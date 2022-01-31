/**
 * # Root
 * 
 * This module sets up a root project in a Google Cloud organization.
 * 
 * Along with its root service account, this project bare full access to the organization and is maximally critical as such.
 * 
 * This code should be used against with application-default credentials of an admin user.
 * 
 * The user should also claim billing account usage to bind the root project with.
 * 
 * A Google Storage bucket is also created to store any critical files related to the root project.
 */

terraform {
  required_version = "~> 1.1.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
  }
}

provider "google" {
  region = var.region
}

provider "random" {
}

data "google_organization" "org" {
  domain = var.organization
}

data "google_billing_account" "primary_account" {
  display_name = var.billing_account
  open         = true
}

resource "random_string" "random" {
  /** 
   * Random string with only lowercase letters and integers.
   * Will be used to generate the root project ID and root bucket
   */
  length      = 16
  keepers     = null
  lower       = true
  min_lower   = 8
  number      = true
  min_numeric = 8
  upper       = false
  special     = false
}

resource "google_project" "root_project" {
  /**
   * Root project of the organization.
   */
  name            = "root"
  project_id      = "root-${random_string.random.result}"
  org_id          = data.google_organization.org.org_id
  billing_account = data.google_billing_account.primary_account.id
  labels = {
    root = true
  }
  // Org policies are not set up at this point so we rely on the auto_create_network feature to remove the root project default network.
  auto_create_network = false
}

resource "google_storage_bucket" "root_bucket" {
  /**
   * Root bucket for the root project.
   */
  name                        = "root-bucket-${random_string.random.result}"
  location                    = var.location
  project                     = google_project.root_project.project_id
  force_destroy               = false
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  retention_policy {
    retention_period = 1800
  }
  labels = {
    root = true
  }
}

resource "google_service_account" "root_account" {
  /**
   * Root service account.
   * Will be granted org admin role.
   }
   */
  account_id   = google_project.root_project.project_id
  display_name = "Root Account"
  description  = "This service account has full acces to the organization.}"
  project      = google_project.root_project.project_id
}

resource "google_service_account_key" "root_key" {
  /**
   * Secret private for the root service account.
   * Highly criticial.
   */
  service_account_id = google_service_account.root_account.name
}

resource "google_storage_bucket_iam_binding" "root_bucket_editors" {
  /**
   * Only the root service account will have read/write access to the bucket.
   */
  bucket = google_storage_bucket.root_bucket.name
  role   = "roles/storage.legacyBucketWriter"
  members = [
    "serviceAccount:${google_service_account.root_account.email}",
  ]
}

resource "google_organization_iam_member" "org_admin" {
  /**
   * Root service account is granted org admin role.
   */
  org_id = data.google_organization.org.org_id
  role   = "roles/resourcemanager.organizationAdmin"
  member = "serviceAccount:${google_service_account.root_account.email}"
}

resource "google_storage_bucket_object" "private_key" {
  /**
   * Root private key is uploaded to root bucket in JSON format.
   */
  name         = "rootkey.json"
  content      = base64decode(google_service_account_key.root_key.private_key)
  content_type = "application/json; charset=utf-8"
  bucket       = google_storage_bucket.root_bucket.name
}