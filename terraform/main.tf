/**
 * # workspace_nucleation
 * 
 * This script sets up a new **workspace** in a *Google Cloud Organization*.
 * To get started, please see the [docs folder](docs/README.md).
 *
 */

terraform {
  required_version = "~> 1.7.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.21.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.53.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }
}

provider "google" {
  region  = var.region
  project = var.project
}

provider "tfe" {
}

provider "random" {
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
  numeric     = true
  min_numeric = local.index_length / 2
  upper       = false
  special     = false
}

resource "google_tags_tag_value" "workspace_tag_value" {
  parent      = var.workspaces_tag_key
  short_name  = local.name
  description = "For resources under ${local.name} workspace."
}

resource "google_project" "administrator_project" {
  /**
   * Master project of the workspace.
   */
  name       = "${local.name} Admin Project"
  project_id = substr("${local.name}-adm-${random_string.workspace_uid.result}", 0, 30)
  folder_id  = var.workspaces_folder
  labels     = merge(local.labels, { uid = random_string.workspace_uid.result })

  skip_delete = false

  lifecycle {
    # The workspace full name must be of the form /^[a-z][a-z0-9]{1,9}[a-z]-v[0-9]{2}$/.
    precondition {
      condition     = can(regex("^[a-z][a-z0-9]{1,12}[a-z]$", local.name))
      error_message = "The name of the workspace should be of the form [a-z][a-z0-9]{1,12}[a-z]."
    }
    ignore_changes = [billing_account]
  }
}

resource "google_billing_project_info" "billing_association" {
  project         = google_project.administrator_project.project_id
  billing_account = var.billing_account
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
  parent       = "folders/${var.workspaces_folder}"
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
  # 365 days rotation period in seconds
  rotation_period = "31536000s"

  # First key version is automatically created when a key is created.
  # you can disable this feature with the extra arguments
  # skip_initial_version_creation = true

  labels = merge(local.labels, { uid = random_string.workspace_uid.result })

  version_template {
    algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION"
  }

  lifecycle {
    prevent_destroy = false
  }
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

data "google_cloud_identity_group_lookup" "billing_group" {
  group_key {
    id = var.billing_email
  }
}

resource "google_cloud_identity_group_membership" "billing_users_membership" {
  group = data.google_cloud_identity_group_lookup.billing_group.name

  preferred_member_key {
    id = google_service_account.administrator.email
  }

  roles {
    name = "MEMBER"
  }
}

resource "tfe_project" "working_project" {
  name         = local.name
  organization = var.tfe_organization
}

resource "tfe_variable_set" "auth_varset" {
  name         = "${title(local.name)} Credentials"
  organization = var.tfe_organization
  description  = "Authentication variables for the ${local.name} workspace."
}

resource "tfe_variable_set" "config_varset" {
  name         = "${title(local.name)} Configuration"
  organization = var.tfe_organization
  description  = "Configuration variables for the ${local.name} workspace."
}

resource "tfe_project_variable_set" "auth_binding" {
  variable_set_id = tfe_variable_set.auth_varset.id
  project_id      = tfe_project.working_project.id
}

resource "tfe_project_variable_set" "config_binding" {
  variable_set_id = tfe_variable_set.config_varset.id
  project_id      = tfe_project.working_project.id
}

resource "tfe_variable" "name" {
  key             = "name"
  value           = local.name
  category        = "terraform"
  sensitive       = false
  description     = "The name of the workspace."
  variable_set_id = tfe_variable_set.config_varset.id
}

resource "tfe_variable" "project" {
  key             = "admin_project"
  value           = google_project.administrator_project.project_id
  category        = "terraform"
  sensitive       = false
  description     = "The ID of the admin project for the workspace. Used to create projects."
  variable_set_id = tfe_variable_set.config_varset.id
}

resource "tfe_variable" "folder" {
  key             = "workspace_folder"
  value           = tonumber(google_folder.workspace_folder.folder_id)
  category        = "terraform"
  sensitive       = false
  description     = "The ID of the workspace folder."
  variable_set_id = tfe_variable_set.config_varset.id
}

resource "tfe_variable" "bucket" {
  key             = "bucket"
  value           = google_storage_bucket.administrator_bucket.name
  category        = "terraform"
  sensitive       = false
  description     = "The name of the administrator bucket."
  variable_set_id = tfe_variable_set.config_varset.id
}

resource "tfe_variable" "run_account" {
  key             = "TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL"
  value           = google_service_account.administrator.email
  category        = "env"
  sensitive       = true
  description     = "The service account email Terraform Cloud will use when authenticating to GCP."
  variable_set_id = tfe_variable_set.auth_varset.id
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

data "google_iam_policy" "folder_policy" {
  binding {
    role = "organizations/${var.organization_id}/roles/workspace.builder"
    members = [
      "serviceAccount:${google_service_account.administrator.email}",
    ]
  }
  binding {
    role = "roles/viewer"
    members = [
      "group:${var.admin_group}",
      "group:${var.policy_group}",
      "group:${var.finops_group}"
    ]
  }
}

resource "google_folder_iam_policy" "folder_policy" {
  folder      = google_folder.workspace_folder.name
  policy_data = data.google_iam_policy.folder_policy.policy_data
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
      "group:${var.admin_group}",
      "group:${var.policy_group}",
      "group:${var.finops_group}",
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
      "group:${var.admin_group}",
    ]
  }
  binding {
    role = "roles/iam.workloadIdentityUser"
    members = [
      "principalSet://iam.googleapis.com/${var.organization_identities}/attribute.terraform_project_id/${tfe_project.working_project.id}",
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
      "group:${var.policy_group}",
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
      "group:${var.admin_group}",
      "group:${var.policy_group}",
      "group:${var.finops_group}"
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
      "group:${var.finops_group}"
    ]
  }
  binding {
    role = "roles/billing.viewer"
    members = [
      "serviceAccount:${google_service_account.administrator.email}",
      "group:${var.admin_group}",
    ]
  }
  binding {
    role = "roles/billing.user"
    members = [
      "serviceAccount:${google_service_account.administrator.email}"
    ]
  }
}

resource "google_tags_tag_value_iam_binding" "tag_viewer" {
  tag_value = google_tags_tag_value.workspace_tag_value.id
  role      = "roles/resourcemanager.tagViewer"
  members = [
    "group:${var.policy_group}",
    "serviceAccount:${google_service_account.policy_administrator.email}"
  ]
}

resource "google_tags_tag_value_iam_binding" "tag_user" {
  tag_value = google_tags_tag_value.workspace_tag_value.id
  role      = "roles/resourcemanager.tagUser"
  members = [
    "serviceAccount:${google_service_account.policy_administrator.email}",
  ]
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
      "group:${var.admin_group}",
    ]
  }
}

resource "google_dns_managed_zone_iam_policy" "dns_policy" {
  project      = google_dns_managed_zone.workspace_dns_zone.project
  managed_zone = google_dns_managed_zone.workspace_dns_zone.name
  policy_data  = data.google_iam_policy.dns_management.policy_data
}