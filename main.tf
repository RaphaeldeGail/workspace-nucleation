/**
 * # workspace_setup
 * 
 * This module sets up a new **workspace** in a *Google Cloud Organization*.
 *
 * ## Introduction
 *
 * A **workspace** is an infrastructure concept for developers to autonomously manage their infrastrucure resources and environments.
 *
 * ### What is a workspace?
 *
 * A **workspace** is a dedicated set of cloud resources for a particular project.
 * It is isolated from other workspaces, and relies on specific common services, such as DNS zone, GCS bucket, etc.
 *
 * ### What is the use of a workspace?
 *
 * Within a workspace, a team can create infrastructure resources in different environments with full autonomy.
 * The resources are bound to a minimal set of common services (DNS zone, etc.) to ensure correct integration with other projects and the outer world.
 *
 * ### How do I use a workspace?
 *
 * Once your workspace has been delivered, you can use it to create your own GCP projects within your own folder.
 * You can create almost any resources in those projects and group them as you need (per environments, per domain, etc.).
 * You can also use the common services of the workspace to manage resources that span among the whole workspace, such as *compute images* for servers among all environments, etc.
 *
 * ### How do I create a workspace?
 *
 * To create a workspace, you will need a name for the workspace (only lowercase letters), and a list of team members for the three default groups: admins, policy-admins and finops.
 * You also need to use this code and follow the instructions below.
 *
 * ## Workspace description
 *
 * Below is a comprehensive description of a workspace.
 *
 * ### Workspace organization
 *
 * A workspace is made of three main parts:
 *
 * - the workspace folder where the team can create all the projects needed for their project,
 * - the ADM (administration) project, where the team can manage the workspace and its common services,
 * - three Google groups, where team members will be added, and which control the workspace.
 *
 * The three Google groups created are:
 *
 * - The *FinOps Group*, with access to billing information about the workspace,
 * - The *Administrators Group*, with access to the workspace,
 * - The *Policy Administrators Group*, with access to policies for the workspace folder.
 *
 * Both the workspace folder and the ADM project belong to the organization level (no parent folder).
 * The workspace folder is initially empty and left to the team to use for their project.
 * The ADM project is initially setup with several services:
 *
 * - Service accounts to manipulate the workspace,
 * - a GCS bucket to store data across the workspace, for instance some configuration files that belong to all the environments,
 * - Access to compute image storage,
 * - a keyring to encrypt the GCS data with a dedicated key.
 *
 * The service accounts in the ADM project are:
 *
 * - the *administrator* service account, with read/write over the workspace, and the workspace folder specifically,
 * - the *policy-administrator* service account, with management rights for policies over the workspace folder.
 *
 * On top of these resources, the workspace is also tagged at several level:
 *
 * - The workspace folder is tagged with the *workspace* key and the **workspace name** as the value,
 * - the ADM project and the GCS bucket are identically tagged.
 *
 * Below is a simple diagram presenting the organization:
 *
 * ![organizational-structure](docs/organizational-structure.svg)
 * *Figure - Organization diagram for the workspace structure.*
 *
 * ### Workspace management
 *
 * The workspace is mainly managed by service accounts, with read/write access to resources.
 * Google groups have mainly read access, but can also impersonate the service accounts.
 *
 * The *administrator* service account is the owner of the workspace folder and thus can create any resource in it.
 * It has also administrative rights to the GCS bucket and the compute image storage.
 *
 * The *Administrators Group* can impersonate the *administrator* service account.
 * The *Policy Administrators Group* can impersonate the *policy-administrator* service account.
 *
 * Below is a simple diagram presenting the organization:
 *
 * ![functional-structure](docs/functional-structure.svg)
 * *Figure - Functional diagram for the workspace structure -*
 * *The yellow blocks represent IAM permissions bound to a user on a resource.*
 *
 * On top of the permissions within the team, the organization administrators remain the owners of the ADM project and of the workspace folder, by inheritance.
 * Only the *builder* service account can create a workspace.
 * Only an organization administrator can delete a workspace.
 *
 * ## Repository presentation
 *
 * TODO: HERE
 *
 * ### Repository structure
 * 
 * *What is in this repo?*
 *
 * ### Repository usage
 *
 * *How do I use this repo to create a workspace?*
 *
 * - Terraform Cloud config (organization, workspace, variables)
 * - Terraform client config
 * - Google Cloud Organization
 * - Root project (Root setup)
 * - builder account with permissions
 * - secretary account
 *
 * Before running this code, you should first create a Google Cloud Platform **organization** (see official documentation).
 *
 * Once you are authenticated with terraform cloud, you can run the script:
 *
 * ```bash
 * ./run.sh
 * ```
 *
 * The workspace structure is then created.
 *
 * TODO: add a DNS zone (public and private)
 *
 * ***
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
  short_name  = local.name
  description = "For resources under ${local.name} workspace."
}

resource "google_project" "administrator_project" {
  /**
   * Master project of the workspace.
   */
  name            = "${local.name} Administration"
  project_id      = "${local.name}-administration"
  org_id          = data.google_organization.organization.org_id
  billing_account = var.billing_account
  labels          = merge(local.labels, { uid = random_string.workspace_uid.result })

  auto_create_network = false
  skip_delete         = true

  lifecycle {
    # The workspace full name must be of the form /^[a-z][a-z0-9]{1,9}[a-z]-v[0-9]{2}$/.
    precondition {
      condition     = can(regex("^[a-z][a-z0-9]{1,9}[a-z]-v[0-9]{2}$", local.name))
      error_message = "The name of the workspace should be of the form [a-z][a-z0-9]{1,9}[a-z]-v[0-9]{2}."
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
  parent       = data.google_organization.organization.name
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
    prevent_destroy = true
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
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key_version" "key_instance" {
  crypto_key = google_kms_crypto_key.symmetric_key.id
}

resource "google_dns_managed_zone" "workspace_dns_zone" {
  project       = google_project.administrator_project.project_id
  name          = "${local.name} Public DNS zone"
  dns_name      = "${local.name}.${var.organization}"
  description   = "Public DNS zone for ${local.name} workspace."
  labels        = merge(local.labels, { uid = random_string.workspace_uid.result })
  visibility    = "public"
  force_destroy = false

  # dnssec_config {
  #   kind = ""
  #   non_existence "nsec3"
  #   state = "on"
  #   default_key_specs {
  #     algorithm = "rsasha256"
  #     key_length = 2048
  #     key_type = "keySigning" # "zoneSigning"
  #     kind = ""
  #   }
  #}
}

resource "google_billing_budget" "workspace_budget" {
  billing_account = var.billing_account
  display_name    = "${local.name} Workspace Billing Budget"
  amount {
    specified_amount {
      currency_code = "EUR"
      units         = "10"
    }
  }
  threshold_rules {
    threshold_percent = 0.5
    spend_basis       = "FORECASTED_SPEND"
  }
  threshold_rules {
    threshold_percent = 0.9
    spend_basis       = "FORECASTED_SPEND"
  }
  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
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

  parent = "customers/${data.google_organization.organization.directory_customer_id}"

  group_key {
    id = "${local.name}-finops@${var.organization}"
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

  parent = "customers/${data.google_organization.organization.directory_customer_id}"

  group_key {
    id = "${local.name}-administrators@${var.organization}"
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

  parent = "customers/${data.google_organization.organization.directory_customer_id}"

  group_key {
    id = "${local.name}-policy-administrators@${var.organization}"
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
      "group:${var.organization_administrators_group}@${var.organization}",
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
      "group:${var.organization_administrators_group}@${var.organization}",
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