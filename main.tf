/**
 * # Root
 * 
 * This module sets up the root structure in a Google Cloud organization.
 *
 * ## Infrastructure description
 *
 * The code creates a root folder as well as a root Google Cloud project, hosting several critical service accounts for the organization.
 *
 * The **project creator** service account can create any project inside the root folder.
 *
 * The **org policy** service account can apply any policy at the organization level.
 * 
 * Along with the root project, a Google Cloud Storage bucket is created to store service accounts private keys and terraform states.
 *
 * ## Usage
 *
 * Before running this code, you should first create a Google Cloud Platform **organization** (see official documentation).
 *
 * You should also have set up a valid **Billing account** for your organization.
 *
 * Set the values of the required variables in terraform.tfvars (specifically billing account ID and organization name).
 * 
 * This code should be used against with **application-default** credentials of an **Organization Administrator**.
 *
 * In order to login with application-default, type:
 * ```bash
 * gcloud auth application-default login
 * ```
 * You will be redirected to a web login interface.
 *
 * The organization administrator should also claim billing account usage.
 *
 * Once you are authenticated with application-default credentials, you can run the script:
 * ```bash
 * ./run.sh
 * ```
 * 
 * The root structure is then created.
 * 
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
  root_name = "root"
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
  name            = local.root_name
  project_id      = join("-", [local.root_name, random_string.random.result])
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
  name                        = join("-", [local.root_name, "bucket", random_string.random.result])
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
  display_name = title(join(" ", [local.root_name, "folder"]))
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