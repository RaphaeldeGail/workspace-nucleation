/**
 * # workspace_setup
 * 
 * This module sets up a new **workspace** in a *Google Cloud Organization*.
 *
 * TODO: fail upon re-creation of Admin project (same ID)
 * TODO: remove static values in objects (tagKeys, folderId, organizationDomain, customersDirectory)
 *
 */

terraform {
  required_version = "~> 1.2.0"
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
  region  = var.region
  project = var.project
}

provider "random" {
}

# data "google_organization" "organization" {
#   domain = var.organization
# }

# data "google_tags_tag_key" "workspace_tag_key" {
#   parent     = "organizations/${var.organization}"
#   short_name = "workspace"
# }

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
  parent      = "tagKeys/269336281057"
  short_name  = local.name
  description = "For resources under ${local.name} workspace."
}

resource "google_project" "administrator_project" {
  /**
   * Master project of the workspace.
   */
  name            = "${local.name} Admin Project"
  project_id      = "${local.name}-administration-${random_string.workspace_uid.result}"
  #org_id          = data.google_organization.organization.org_id
  folder_id       = "578502317468"
  billing_account = var.billing_account
  labels          = merge(local.labels, { uid = random_string.workspace_uid.result })

  auto_create_network = false
  skip_delete         = true

  lifecycle {
    # The workspace full name must be of the form /^[a-z][a-z0-9]{1,9}[a-z]-v[0-9]{2}$/.
    precondition {
      condition     = can(regex("^[a-z][a-z0-9]{1,12}[a-z]$", local.name))
      error_message = "The name of the workspace should be of the form [a-z][a-z0-9]{1,12}[a-z]."
    }
  }
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

  # The bucket can not be created if the KMS key is not usable by the Cloud Storage service agent.
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
  display_name = "${local.name} Workspace Administrator Service Account"
  description  = "This service account has full acces to folder ${google_folder.workspace_folder.display_name} with numeric ID: ${google_folder.workspace_folder.id}."
  project      = google_project.administrator_project.project_id
}

resource "google_service_account" "policy_administrator" {
  account_id   = "policy-administrator"
  display_name = "${local.name} Workspace Policy Administrator Service Account"
  description  = "This service account has full acces to policies for folder ${google_folder.workspace_folder.display_name} with numeric ID: ${google_folder.workspace_folder.id}."
  project      = google_project.administrator_project.project_id
}

resource "google_folder" "workspace_folder" {
  display_name = "${local.name} Workspace"
  parent       = "folders/578502317468"
}

resource "google_tags_tag_binding" "workspace_folder_tag_binding" {
  parent    = "//cloudresourcemanager.googleapis.com/${google_folder.workspace_folder.name}"
  tag_value = google_tags_tag_value.workspace_tag_value.id
}

resource "google_kms_key_ring" "workspace_keyring" {
  project = google_project.administrator_project.project_id

  name     = "${local.name}-keyring"
  location = var.region

  lifecycle {
    prevent_destroy = false
  }

  depends_on = [
    google_project_service.administrator_api["cloudkms.googleapis.com"]
  ]
}

resource "google_kms_crypto_key" "symmetric_key" {
  name     = "${local.name}-symmetric-key"
  key_ring = google_kms_key_ring.workspace_keyring.id
  purpose  = "ENCRYPT_DECRYPT"
  # 30 days rotation period in seconds
  rotation_period = "2592000s"

  labels = merge(local.labels, { uid = random_string.workspace_uid.result })

  version_template {
    algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_kms_crypto_key_version" "key_instance" {
  crypto_key = google_kms_crypto_key.symmetric_key.id
}

resource "google_dns_managed_zone" "workspace_dns_zone" {
  project       = google_project.administrator_project.project_id
  name          = "${local.name}-public-zone"
  dns_name      = "${local.name}.${var.organization}."
  description   = "Public DNS zone for ${local.name} workspace."
  labels        = merge(local.labels, { uid = random_string.workspace_uid.result })
  visibility    = "public"
  force_destroy = false

  dnssec_config {
    kind          = "dns#managedZoneDnsSecConfig"
    non_existence = "nsec3"
    state         = "on"
    default_key_specs {
      algorithm  = "rsasha256"
      key_length = 2048
      key_type   = "zoneSigning"
      kind       = "dns#dnsKeySpec"
    }
    default_key_specs {
      algorithm  = "rsasha256"
      key_length = 2048
      key_type   = "keySigning"
      kind       = "dns#dnsKeySpec"
    }
  }

  depends_on = [
    google_project_service.administrator_api["dns.googleapis.com"]
  ]
}

data "google_dns_keys" "workspace_dns_keys" {
  managed_zone = google_dns_managed_zone.workspace_dns_zone.id
}

resource "google_billing_budget" "workspace_budget" {
  billing_account = var.billing_account
  display_name    = "${local.name} Workspace Billing Budget"
  amount {
    specified_amount {
      currency_code = "EUR"
      units         = tostring(var.budget_allowed)
    }
  }
  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }
  threshold_rules {
    threshold_percent = 0.9
    spend_basis       = "FORECASTED_SPEND"
  }
  threshold_rules {
    threshold_percent = 0.5
    spend_basis       = "FORECASTED_SPEND"
  }
  budget_filter {
    projects = ["projects/${google_project.administrator_project.number}"]
  }
}

/**
 * Google Groups
 */

resource "google_cloud_identity_group" "finops_group" {
  display_name         = "${local.name} FinOps"
  description          = "Financial operators of the ${local.name} workspace."
  initial_group_config = "WITH_INITIAL_OWNER"

  parent = "customers/C03krtmmy"

  group_key {
    id = "${local.name}-finops@wansho.fr"
  }

  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }

  depends_on = [
    google_project_service.administrator_api["cloudidentity.googleapis.com"]
  ]
}

resource "google_cloud_identity_group" "administrators_group" {
  display_name         = "${local.name} Administrators"
  description          = "Administrators of the ${local.name} workspace."
  initial_group_config = "WITH_INITIAL_OWNER"

  parent = "customers/C03krtmmy"

  group_key {
    id = "${local.name}-administrators@wansho.fr"
  }

  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }

  depends_on = [
    google_project_service.administrator_api["cloudidentity.googleapis.com"]
  ]
}

resource "google_cloud_identity_group" "policy_administrators_group" {
  display_name         = "${local.name} Policy Administrators"
  description          = "Policy Administrators of the ${local.name} workspace."
  initial_group_config = "WITH_INITIAL_OWNER"

  parent = "customers/C03krtmmy"

  group_key {
    id = "${local.name}-policy-administrators@wansho.fr"
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

resource "google_folder_iam_member" "folder_admin" {
  folder = google_folder.workspace_folder.name
  role   = "roles/resourcemanager.folderAdmin"
  member = "serviceAccount:${google_service_account.administrator.email}"
}

resource "google_folder_iam_member" "folder_project_creator" {
  folder = google_folder.workspace_folder.name
  role   = "roles/resourcemanager.projectCreator"
  member = "serviceAccount:${google_service_account.administrator.email}"
}

resource "google_folder_iam_member" "folder_admin_viewer" {
  folder = google_folder.workspace_folder.name
  role   = "roles/viewer"
  member = "group:${google_cloud_identity_group.administrators_group.group_key[0].id}"
}

resource "google_folder_iam_member" "folder_policy_viewer" {
  folder = google_folder.workspace_folder.name
  role   = "roles/viewer"
  member = "group:${google_cloud_identity_group.policy_administrators_group.group_key[0].id}"
}

resource "google_folder_iam_member" "folder_finops_viewer" {
  folder = google_folder.workspace_folder.name
  role   = "roles/viewer"
  member = "group:${google_cloud_identity_group.finops_group.group_key[0].id}"
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
      "serviceAccount:${google_service_account.administrator.email}",
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

# This data is solely called to force Google Cloud to activate the Storage service agent.
data "google_storage_project_service_account" "gcs_account" {
  project = google_project.administrator_project.project_id
}

data "google_iam_policy" "kms_key_usage" {
  binding {
    role = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
    members = [
      "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}",
    ]
  }
  binding {
    role = "roles/cloudkms.admin"
    members = [
      "serviceAccount:${google_service_account.administrator.email}",
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

data "google_iam_policy" "dns_management" {
  binding {
    role = "roles/dns.admin"
    members = [
      "serviceAccount:${google_service_account.administrator.email}",
    ]
  }
  binding {
    role = "roles/dns.reader"
    members = [
      "group:${google_cloud_identity_group.administrators_group.group_key[0].id}",
    ]
  }
}

resource "google_dns_managed_zone_iam_policy" "dns_policy" {
  project      = google_dns_managed_zone.workspace_dns_zone.project
  managed_zone = google_dns_managed_zone.workspace_dns_zone.name
  policy_data  = data.google_iam_policy.dns_management.policy_data
}