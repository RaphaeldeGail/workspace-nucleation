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
 * ## Organization description
 *
 * The root structure attemps to create a sub-organization inside the Google Cloud Platform.
 *
 * Security is then preserved since the original organization is never used apart for creating the root structure.
 *
 * Below is a simple diagram presenting the structure:
 *
 * ![organizational-structure](docs/organizational-structure.png)
 * *Figure - Organization diagram for the root structure.*
 *
 * ### Cloud identity
 *
 * Users and groups
 *
 * ### Cloud organization
 *
 * IAM and resources
 *
 * ### Root project
 *
 * Service accounts
 *
 * ### Root folder
 *
 * Workspaces
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

// Review the creation of groups with cloud identity in conflict with project creation.
// Review the finops inception of groups with group managers.
// Around 30 projects can be created under default quota.
// A *direct* billing account can only attach up to 5 projects. Then you can create a new billing account if needed.
// The maxmimum number of billing account you can create is unknown.

terraform {
  cloud {
    organization = "raphaeldegail"
    workspaces {
      tags = ["workspace", "wansho", "gcp"]
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

provider "google" {
  /**
   * This is a workaround to manage group membership as it requires either a service account (none created yet) or a billing project declare for the client.
   * We create an alternative provider which points to the root project for the billing project.
   * The alternative provider avoids cyclic dependencies since it is only called after the root project has been created.
   */
  region = var.region

  alias                 = "cloud_identity"
  user_project_override = true
  billing_project       = google_project.administrator_project.project_id
}

provider "random" {
}

data "google_organization" "organization" {
  domain = var.organization
}

data "google_active_folder" "parent_folder" {
  count = var.parent == null ? 0 : 1

  display_name = "${var.parent} Workspace Folder"
  parent       = data.google_organization.organization.name
}

data "google_cloud_identity_groups" "parent_groups" {
  provider = google.cloud_identity

  parent = "customers/C03krtmmy"

  depends_on = [
    google_project_service.administrator_api["cloudidentity.googleapis.com"]
  ]
}

resource "random_string" "workspace_uid" {
  /** 
   * Unique ID as a random string with only lowercase letters and integers.
   * Will be used to generate the root bucket name.
   */
  length      = local.index_length
  keepers     = null
  lower       = true
  min_lower   = local.index_length / 2
  number      = true
  min_numeric = local.index_length / 2
  upper       = false
  special     = false
}

resource "google_project" "administrator_project" {
  /**
   * Master project of the workspace.
   */
  name            = "${local.workspace_name} Workspace"
  project_id      = "${local.workspace_name}-workspace"
  org_id          = var.parent == null ? data.google_organization.organization.org_id : null
  billing_account = var.billing_account
  folder_id       = one(data.google_active_folder.parent_folder[*].name)
  labels          = merge(local.labels, { uid = random_string.workspace_uid.result })

  auto_create_network = false
  skip_delete         = true
}

resource "google_project_service" "administrator_api" {
  for_each = toset(local.apis)

  project = google_project.administrator_project.project_id
  service = each.value

  disable_dependent_services = true
  disable_on_destroy         = true

  timeouts {
    create = "30m"
    update = "40m"
  }
}

resource "google_storage_bucket" "administrator_bucket" {
  name                        = format("%s-%s", google_project.administrator_project.project_id, random_string.workspace_uid.result)
  location                    = var.region
  project                     = google_project.administrator_project.project_id
  force_destroy               = false
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  labels = merge(local.labels, { uid = random_string.workspace_uid.result })
}

resource "google_service_account" "administrator" {
  account_id   = "administrator"
  display_name = "${local.workspace_name} Workspace Administrator Service Account"
  description  = "This service account has full acces to folder ${google_folder.workspace_folder.display_name} with numeric ID: ${google_folder.workspace_folder.id}."
  project      = google_project.administrator_project.project_id
}

resource "google_service_account" "policy_administrator" {
  account_id   = "policy-administrator"
  display_name = "${local.workspace_name} Workspace Policy Administrator Service Account"
  description  = "This service account has full acces to policies for folder ${google_folder.workspace_folder.display_name} with numeric ID: ${google_folder.workspace_folder.id}."
  project      = google_project.administrator_project.project_id
}

resource "google_folder" "workspace_folder" {
  display_name = "${local.workspace_name} Workspace"
  parent       = var.parent == null ? data.google_organization.organization.name : one(data.google_active_folder.parent_folder[*].name)
}

/**
 * Google Groups
 */

resource "google_cloud_identity_group" "finops_group" {
  provider = google.cloud_identity

  display_name         = "${local.workspace_name} FinOps"
  description          = "Financial operators of the ${local.workspace_name} workspace."
  initial_group_config = "WITH_INITIAL_OWNER"

  parent = "customers/C03krtmmy"

  group_key {
    id = "${local.workspace_name}-finops@wansho.fr"
  }

  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }

  depends_on = [
    google_project_service.administrator_api["cloudidentity.googleapis.com"]
  ]
}

resource "google_cloud_identity_group" "administrators_group" {
  provider = google.cloud_identity

  display_name         = "${local.workspace_name} Administrators"
  description          = "Administrators of the ${local.workspace_name} workspace."
  initial_group_config = "WITH_INITIAL_OWNER"

  parent = "customers/C03krtmmy"

  group_key {
    id = "${local.workspace_name}-administrators@wansho.fr"
  }

  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }

  depends_on = [
    google_project_service.administrator_api["cloudidentity.googleapis.com"]
  ]
}

resource "google_cloud_identity_group" "policy_administrators_group" {
  provider = google.cloud_identity

  display_name         = "${local.workspace_name} Policy Administrators"
  description          = "Policy Administrators of the ${local.workspace_name} workspace."
  initial_group_config = "WITH_INITIAL_OWNER"

  parent = "customers/C03krtmmy"

  group_key {
    id = "${local.workspace_name}-policy-administrators@wansho.fr"
  }

  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }

  depends_on = [
    google_project_service.administrator_api["cloudidentity.googleapis.com"]
  ]
}

resource "google_cloud_identity_group_membership" "finops_group_manager" {
  provider = google.cloud_identity
  for_each = toset(var.team.finops)

  group = google_cloud_identity_group.finops_group.id

  preferred_member_key {
    id = each.value
  }
  roles {
    name = "MEMBER"
  }
  roles {
    name = "MANAGER"
  }
}

resource "google_cloud_identity_group_membership" "finops_group_member" {
  provider = google.cloud_identity

  group = google_cloud_identity_group.finops_group.id

  preferred_member_key {
    id = google_cloud_identity_group.administrators_group.group_key[0].id
  }
  roles {
    name = "MEMBER"
  }
}

resource "google_cloud_identity_group_membership" "administrators_group_manager" {
  provider = google.cloud_identity
  for_each = toset(var.team.administrators)

  group = google_cloud_identity_group.administrators_group.id

  preferred_member_key {
    id = each.value
  }
  roles {
    name = "MEMBER"
  }
  roles {
    name = "MANAGER"
  }
}

resource "google_cloud_identity_group_membership" "policy_administrators_group_manager" {
  provider = google.cloud_identity
  for_each = toset(var.team.policy_administrators)

  group = google_cloud_identity_group.policy_administrators_group.id

  preferred_member_key {
    id = each.value
  }
  roles {
    name = "MEMBER"
  }
  roles {
    name = "MANAGER"
  }
}

resource "google_cloud_identity_group_membership" "parent_finops_group_member" {
  provider = google.cloud_identity

  group = var.parent == null ? "groups/01yyy98l12yhqe4" : "groups/01d96cc04ggk3sh"

  preferred_member_key {
    id = google_cloud_identity_group.finops_group.group_key[0].id
  }
  roles {
    name = "MEMBER"
  }
}

/**
 * Identity and Access Management
 */

resource "google_project_iam_custom_role" "image_manager_role" {
  role_id     = "imageManager"
  title       = "Image Manager"
  description = "Can create and use compute images."
  project     = google_project.administrator_project.project_id

  permissions = [
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
}

data "google_iam_policy" "folder_admin" {
  binding {
    role = "roles/resourcemanager.folderAdmin"

    members = [
      "serviceAccount:${google_service_account.administrator.email}",
    ]
  }

  binding {
    role = "roles/resourcemanager.projectCreator"

    members = [
      "serviceAccount:${google_service_account.administrator.email}",
    ]
  }

  binding {
    role = "roles/viewer"

    members = [
      "group:${google_cloud_identity_group.administrators_group.group_key[0].id}",
      "group:${google_cloud_identity_group.policy_administrators_group.group_key[0].id}",
      "group:${google_cloud_identity_group.finops_group.group_key[0].id}"
    ]
  }
}

data "google_iam_policy" "project_admin" {
  binding {
    role = "roles/compute.serviceAgent"

    members = [
      "serviceAccount:service-${google_project.administrator_project.number}@compute-system.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/editor"

    members = [
      "serviceAccount:${google_project.administrator_project.number}@cloudservices.gserviceaccount.com"
    ]
  }

  binding {
    role = "roles/owner"

    members = [
      var.parent == null ? "group:org-administrators@wansho.fr" : "serviceAccount:administrator@${var.parent}-workspace.iam.gserviceaccount.com"
    ]
  }

  binding {
    role = google_project_iam_custom_role.image_manager_role.id

    members = [
      "serviceAccount:${google_service_account.administrator.email}",
    ]
  }

  binding {
    role = "roles/viewer"

    members = [
      "group:${google_cloud_identity_group.administrators_group.group_key[0].id}",
      "group:${google_cloud_identity_group.policy_administrators_group.group_key[0].id}",
      "group:${google_cloud_identity_group.finops_group.group_key[0].id}",
      "serviceAccount:${google_service_account.administrator.email}",
    ]
  }
}

data "google_iam_policy" "administrator_admin" {
  binding {
    role = "roles/iam.serviceAccountTokenCreator"

    members = [
      "group:${google_cloud_identity_group.administrators_group.group_key[0].id}",
    ]
  }
}

data "google_iam_policy" "policy_administrator_admin" {
  binding {
    role = "roles/iam.serviceAccountTokenCreator"

    members = [
      "group:${google_cloud_identity_group.policy_administrators_group.group_key[0].id}",
    ]
  }
}

data "google_iam_policy" "bucket_admin" {
  binding {
    role = "roles/storage.objectAdmin"

    members = [
      "serviceAccount:${google_service_account.administrator.email}",
      "serviceAccount:${google_service_account.policy_administrator.email}",
    ]
  }

  binding {
    role = "roles/storage.admin"

    members = [
      var.parent == null ? "group:org-administrators@wansho.fr" : "serviceAccount:administrator@${var.parent}-workspace.iam.gserviceaccount.com"
    ]
  }

  binding {
    role = "roles/storage.objectViewer"

    members = [
      "group:${google_cloud_identity_group.administrators_group.group_key[0].id}",
      "group:${google_cloud_identity_group.policy_administrators_group.group_key[0].id}",
      "group:${google_cloud_identity_group.finops_group.group_key[0].id}"
    ]
  }
}

resource "google_folder_iam_policy" "folder_access" {
  folder      = google_folder.workspace_folder.name
  policy_data = data.google_iam_policy.folder_admin.policy_data
}

resource "google_storage_bucket_iam_policy" "bucket_access" {
  bucket      = google_storage_bucket.administrator_bucket.name
  policy_data = data.google_iam_policy.bucket_admin.policy_data
}

resource "google_project_iam_policy" "project_access" {
  project     = google_project.administrator_project.project_id
  policy_data = data.google_iam_policy.project_admin.policy_data
}

resource "google_service_account_iam_policy" "administrator_access" {
  service_account_id = google_service_account.administrator.name
  policy_data        = data.google_iam_policy.administrator_admin.policy_data
}

resource "google_service_account_iam_policy" "policy_administrator_access" {
  service_account_id = google_service_account.policy_administrator.name
  policy_data        = data.google_iam_policy.policy_administrator_admin.policy_data
}