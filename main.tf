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

locals {
  apis = [
    "orgpolicy.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ]
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
  project_id      = join("-", ["root", random_string.random.result])
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
  /*
  Required
    display_name (String) The folder’s display name. A folder’s display name must be unique amongst its siblings, e.g. no two folders with the same parent can share the same display name. The display name must start and end with a letter or digit, may contain letters, digits, spaces, hyphens and underscores and can be no longer than 30 characters.
    parent (String) The resource name of the parent Folder or Organization. Must be of the form folders/{folder_id} or organizations/{org_id}.
  */
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

resource "google_folder_iam_binding" "environment_folder_admins" {
  /*
  Required
    member/members (String) Identities that will be granted the privilege in role. Each entry can have one of the following values:
        user:{emailid}: An email address that represents a specific Google account. For example, alice@gmail.com or joe@example.com.
        serviceAccount:{emailid}: An email address that represents a service account. For example, my-other-app@appspot.gserviceaccount.com.
        group:{emailid}: An email address that represents a Google group. For example, admins@example.com.
        domain:{domain}: A G Suite domain (primary, instead of alias) name that represents all the users of that domain. For example, google.com or example.com.
    role (String) The role that should be applied. Only one google_folder_iam_binding can be used per role. Note that custom roles must be of the format organizations/{{org_id}}/roles/{{role_id}}.
    folder (String) The resource name of the folder the policy is attached to. Its format is folders/{folder_id}.

  Optional
    condition (Block) An IAM Condition for a given binding. Structure is documented below.
      Required
        expression (String) Textual representation of an expression in Common Expression Language syntax.
        title (String) A title for the expression, i.e. a short string describing its purpose.
      Optional
        description (String) An optional description of the expression. This is a longer text which describes the expression, e.g. when hovered over it in a UI.
  */
  folder = google_folder.root_folder.name
  role   = "roles/resourcemanager.folderAdmin"
  members = [
    "serviceAccount:${module.service_account["project_creator"].service_account_email}",
  ]
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