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

// Update docs

terraform {
  cloud {
    organization = "wansho"
    workspaces {
      tags = ["workspace", "wansho", "gcp"]
    }
  }
  required_version = "~> 1.1.2"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.53.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
  }
}

provider "google" {
  credentials = var.credentials

  impersonate_service_account = var.builder_account
  region                      = var.region
}

provider "random" {
}

data "google_organization" "organization" {
  domain = var.organization
}

data "google_tags_tag_key" "workspace_tag_key" {
  parent     = data.google_organization.organization.name
  short_name = "workspace"
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

resource "google_tags_tag_value" "workspace_tag_value" {
  parent      = data.google_tags_tag_key.workspace_tag_key.id
  short_name  = var.name
  description = "For resources under ${var.name} workspace."
}

resource "google_project" "administrator_project" {
  /**
   * Master project of the workspace.
   */
  name            = "${var.name} Administration"
  project_id      = "${var.name}-administration"
  org_id          = data.google_organization.organization.org_id
  billing_account = var.billing_account
  labels          = merge(local.labels, { uid = random_string.workspace_uid.result })

  auto_create_network = false
  skip_delete         = true
}

resource "google_tags_tag_binding" "workspace_tag_binding" {
  parent    = "//cloudresourcemanager.googleapis.com/projects/${google_project.administrator_project.number}"
  tag_value = google_tags_tag_value.workspace_tag_value.id
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
  encryption {
    default_kms_key_name = google_kms_crypto_key.symmetric_key.id
  }

  labels = merge(local.labels, { uid = random_string.workspace_uid.result })

  depends_on = [
    google_kms_crypto_key_iam_policy.kms_key_policy
  ]
}

resource "google_tags_location_tag_binding" "bucket_tag_binding" {
  parent    = "//storage.googleapis.com/projects/_/buckets/${google_storage_bucket.administrator_bucket.name}"
  tag_value = google_tags_tag_value.workspace_tag_value.id
  location  = var.region
}

resource "google_service_account" "administrator" {
  account_id   = "administrator"
  display_name = "${var.name} Workspace Administrator Service Account"
  description  = "This service account has full acces to folder ${google_folder.workspace_folder.display_name} with numeric ID: ${google_folder.workspace_folder.id}."
  project      = google_project.administrator_project.project_id
}

resource "google_service_account" "policy_administrator" {
  account_id   = "policy-administrator"
  display_name = "${var.name} Workspace Policy Administrator Service Account"
  description  = "This service account has full acces to policies for folder ${google_folder.workspace_folder.display_name} with numeric ID: ${google_folder.workspace_folder.id}."
  project      = google_project.administrator_project.project_id
}

resource "google_folder" "workspace_folder" {
  display_name = "${var.name} Workspace"
  parent       = data.google_organization.organization.name
}

resource "google_tags_tag_binding" "workspace_folder_tag_binding" {
  parent    = "//cloudresourcemanager.googleapis.com/${google_folder.workspace_folder.name}"
  tag_value = google_tags_tag_value.workspace_tag_value.id
}

resource "google_kms_key_ring" "workspace_keyring" {
  project = google_project.administrator_project.project_id

  name     = "${var.name}-keyring"
  location = var.region

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [
    google_project_service.administrator_api["cloudkms.googleapis.com"]
  ]
}

resource "google_kms_crypto_key" "symmetric_key" {
  name            = "${var.name}-symmetric-key"
  key_ring        = google_kms_key_ring.workspace_keyring.id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = "100000s"

  labels = merge(local.labels, { uid = random_string.workspace_uid.result })

  version_template {
    algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key_version" "key_instance" {
  crypto_key = google_kms_crypto_key.symmetric_key.id
}

/**
 * Google Groups
 */

resource "google_cloud_identity_group" "finops_group" {
  display_name         = "${var.name} FinOps"
  description          = "Financial operators of the ${var.name} workspace."
  initial_group_config = "WITH_INITIAL_OWNER"

  parent = "customers/${var.cloud_identity_id}"

  group_key {
    id = "${var.name}-finops@wansho.fr"
  }

  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }

  depends_on = [
    google_project_service.administrator_api["cloudidentity.googleapis.com"]
  ]
}

resource "google_cloud_identity_group" "administrators_group" {
  display_name         = "${var.name} Administrators"
  description          = "Administrators of the ${var.name} workspace."
  initial_group_config = "WITH_INITIAL_OWNER"

  parent = "customers/${var.cloud_identity_id}"

  group_key {
    id = "${var.name}-administrators@wansho.fr"
  }

  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }

  depends_on = [
    google_project_service.administrator_api["cloudidentity.googleapis.com"]
  ]
}

resource "google_cloud_identity_group" "policy_administrators_group" {
  display_name         = "${var.name} Policy Administrators"
  description          = "Policy Administrators of the ${var.name} workspace."
  initial_group_config = "WITH_INITIAL_OWNER"

  parent = "customers/${var.cloud_identity_id}"

  group_key {
    id = "${var.name}-policy-administrators@wansho.fr"
  }

  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }

  depends_on = [
    google_project_service.administrator_api["cloudidentity.googleapis.com"]
  ]
}

resource "google_cloud_identity_group_membership" "finops_group_manager" {
  for_each = toset(var.team.finops)

  group = google_cloud_identity_group.finops_group.id

  preferred_member_key {
    id = each.value
  }
  roles {
    name = "MEMBER"
  }
  roles {
    name = "OWNER"
  }
}

resource "google_cloud_identity_group_membership" "administrators_group_manager" {
  for_each = toset(var.team.administrators)

  group = google_cloud_identity_group.administrators_group.id

  preferred_member_key {
    id = each.value
  }
  roles {
    name = "MEMBER"
  }
  roles {
    name = "OWNER"
  }
}

resource "google_cloud_identity_group_membership" "policy_administrators_group_manager" {
  for_each = toset(var.team.policy_administrators)

  group = google_cloud_identity_group.policy_administrators_group.id

  preferred_member_key {
    id = each.value
  }
  roles {
    name = "MEMBER"
  }
  roles {
    name = "OWNER"
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

  permissions = local.image_manager_permissions
}

data "google_iam_policy" "management" {
  binding {
    role = "roles/resourcemanager.folderAdmin"

    members = [
      "serviceAccount:${google_service_account.administrator.email}",
      "serviceAccount:${var.builder_account}"
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

resource "google_folder_iam_policy" "folder_policy" {
  folder      = google_folder.workspace_folder.name
  policy_data = data.google_iam_policy.management.policy_data
}

data "google_iam_policy" "ownership" {
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
      "group:org-administrators@wansho.fr",
      "serviceAccount:${var.builder_account}"
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

resource "google_project_iam_policy" "project_policy" {
  project     = google_project.administrator_project.project_id
  policy_data = data.google_iam_policy.ownership.policy_data
}

data "google_iam_policy" "administrators_impersonation" {
  binding {
    role = "roles/iam.serviceAccountTokenCreator"

    members = [
      "group:${google_cloud_identity_group.administrators_group.group_key[0].id}",
    ]
  }
}

resource "google_service_account_iam_policy" "administrator_service_account_policy" {
  service_account_id = google_service_account.administrator.name
  policy_data        = data.google_iam_policy.administrators_impersonation.policy_data
}

data "google_iam_policy" "policy_administrators_impersonation" {
  binding {
    role = "roles/iam.serviceAccountTokenCreator"

    members = [
      "group:${google_cloud_identity_group.policy_administrators_group.group_key[0].id}",
    ]
  }
}

resource "google_service_account_iam_policy" "policy_administrator_service_account_policy" {
  service_account_id = google_service_account.policy_administrator.name
  policy_data        = data.google_iam_policy.policy_administrators_impersonation.policy_data
}

data "google_iam_policy" "storage_management" {
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
      "group:org-administrators@wansho.fr",
      "serviceAccount:${var.builder_account}"
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

resource "google_storage_bucket_iam_policy" "bucket_policy" {
  bucket      = google_storage_bucket.administrator_bucket.name
  policy_data = data.google_iam_policy.storage_management.policy_data
}

data "google_iam_policy" "billing_management" {
  binding {
    role = "roles/billing.admin"

    members = [
      "group:${google_cloud_identity_group.finops_group.group_key[0].id}"
    ]
  }

  binding {
    role = "roles/billing.viewer"

    members = [
      "serviceAccount:${google_service_account.administrator.email}",
      "group:${google_cloud_identity_group.administrators_group.group_key[0].id}",
    ]
  }

  binding {
    role = "roles/billing.user"

    members = [
      "serviceAccount:${google_service_account.administrator.email}"
    ]
  }
}

resource "google_billing_account_iam_policy" "billing_account_policy" {
  billing_account_id = var.billing_account
  policy_data        = data.google_iam_policy.billing_management.policy_data
}

data "google_iam_policy" "tags_usage" {
  binding {
    role = "roles/resourcemanager.tagViewer"

    members = [
      "group:${google_cloud_identity_group.policy_administrators_group.group_key[0].id}",
      "serviceAccount:${google_service_account.policy_administrator.email}"
    ]
  }

  binding {
    role = "roles/resourcemanager.tagUser"

    members = [
      "serviceAccount:${google_service_account.policy_administrator.email}",
    ]
  }
}

resource "google_tags_tag_value_iam_policy" "tags_policy" {
  tag_value   = google_tags_tag_value.workspace_tag_value.id
  policy_data = data.google_iam_policy.tags_usage.policy_data
}

data "google_iam_policy" "kms_key_usage" {
  binding {
    role = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

    members = [
      "serviceAccount:service-${google_project.administrator_project.number}@gs-project-accounts.iam.gserviceaccount.com",
    ]
  }

  binding {
    role = "roles/cloudkms.admin"

    members = [
      "serviceAccount:${var.builder_account}",
    ]
  }
}

resource "google_kms_crypto_key_iam_policy" "kms_key_policy" {
  crypto_key_id = google_kms_crypto_key.symmetric_key.id
  policy_data   = data.google_iam_policy.kms_key_usage.policy_data

  depends_on = [
    google_project_service.administrator_api["storage.googleapis.com"]
  ]
}