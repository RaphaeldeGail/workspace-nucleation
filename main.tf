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
  cloud {
    organization = "raphaeldegail"

    workspaces {
      name = "gcp-wansho-root"
    }
  }
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

locals {
  apis = [
    "orgpolicy.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "serviceusage.googleapis.com",
    "iam.googleapis.com",
    "cloudidentity.googleapis.com"
  ]
}

data "google_organization" "org" {
  domain = var.organization
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
  project_id      = join("-", ["root", random_string.random.result])
  org_id          = data.google_organization.org.org_id
  billing_account = var.billing_account
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
  name                        = join("-", ["root", "bucket", random_string.random.result])
  location                    = var.location
  project                     = google_project.root_project.project_id
  force_destroy               = false
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  labels = {
    root = true
  }
}

resource "google_folder" "root_folder" {
  display_name = join(" ", ["Root", "Folder"])
  parent       = data.google_organization.org.name
}

module "service_account" {
  source   = "./modules/service account"
  for_each = var.service_accounts

  org_id      = data.google_organization.org.org_id
  full_name   = each.key
  description = each.value.description
  project_id  = google_project.root_project.project_id
  bucket_name = google_storage_bucket.root_bucket.name
  roles       = each.value.roles
}

resource "google_folder_iam_member" "root_folder_admins" {
  folder = google_folder.root_folder.name
  role   = "roles/resourcemanager.folderAdmin"
  member = "serviceAccount:${module.service_account["project_creator"].service_account_email}"
}

resource "google_folder_iam_member" "root_folder_project_creator" {
  folder = google_folder.root_folder.name
  role   = "roles/resourcemanager.projectCreator"
  member = "serviceAccount:${module.service_account["project_creator"].service_account_email}"
}

resource "google_project_service" "service" {
  for_each = toset(local.apis)

  project = google_project.root_project.project_id
  service = each.value

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_dependent_services = true
  disable_on_destroy         = true
}