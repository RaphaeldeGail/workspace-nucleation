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

terraform {
  cloud {
    organization = "raphaeldegail"
    workspaces {
      name = "root-1"
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

resource "random_string" "workspace_uid" {
  /** 
   * Unique ID as a random string with only lowercase letters and integers.
   * Will be used to generate the root project ID and root bucket.
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
  name            = join(" ", concat(local.workspace_name, ["Project"]))
  project_id      = lower(join("-", concat(local.workspace_name, [random_string.workspace_uid.result])))
  org_id          = var.folder == null ? data.google_organization.organization.org_id : null
  billing_account = var.billing_account
  folder_id       = var.folder
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
  name                        = google_project.administrator_project.project_id
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

resource "google_service_account" "finops" {
  account_id   = lower(join("-", concat(local.workspace_name, ["finops"])))
  display_name = join(" ", concat(local.workspace_name, ["FinOps Service Account"]))
  description  = "This service account has full acces to facturation for folder ${google_folder.workspace_folder.display_name} with numeric ID: ${google_folder.workspace_folder.id}."
  project      = google_project.administrator_project.project_id
}

resource "google_service_account" "administrator" {
  account_id   = lower(join("-", concat(local.workspace_name, ["administrator"])))
  display_name = join(" ", concat(local.workspace_name, ["Administrator Service Account"]))
  description  = "This service account has full acces to folder ${google_folder.workspace_folder.display_name} with numeric ID: ${google_folder.workspace_folder.id}."
  project      = google_project.administrator_project.project_id
}

resource "google_service_account" "policy_administrator" {
  account_id   = lower(join("-", concat(local.workspace_name, ["policy-administrator"])))
  display_name = join(" ", concat(local.workspace_name, ["Policy Administrator Service Account"]))
  description  = "This service account has full acces to policies for folder ${google_folder.workspace_folder.display_name} with numeric ID: ${google_folder.workspace_folder.id}."
  project      = google_project.administrator_project.project_id
}

resource "google_service_account" "administrator_secretary" {
  account_id   = lower(join("-", concat(local.workspace_name, ["secretary"])))
  display_name = join(" ", concat(local.workspace_name, ["Administrator Secretary Service Account"]))
  description  = "This service account has full acces to the administrator project ${google_project.administrator_project.name} with numeric ID: ${google_project.administrator_project.number}"
  project      = google_project.administrator_project.project_id
}

resource "google_compute_network" "administrator_network" {
  project     = google_project.administrator_project.project_id
  name        = "administrator-network"
  description = "Network for administrative usage."

  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  delete_default_routes_on_create = true

  depends_on = [
    google_project_service.administrator_api["compute.googleapis.com"]
  ]
}

resource "google_compute_subnetwork" "instance_subnetwork" {
  project     = google_project.administrator_project.project_id
  name        = "instance-subnetwork"
  description = "Subnetwork hosting instances for administrative usage."

  network                  = google_compute_network.administrator_network.id
  ip_cidr_range            = cidrsubnet(local.base_cidr_block, 2, 0)
  stack_type               = "IPV4_ONLY"
  private_ip_google_access = true
}

resource "google_compute_route" "internet_route" {
  project     = google_project.administrator_project.project_id
  name        = "route-${lower(var.name)}-to-internet"
  description = "Default route for \"${lower(var.name)}\" tagged instances to the internet."

  network          = google_compute_network.administrator_network.name
  dest_range       = "0.0.0.0/0"
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
  tags             = [lower(var.name)]
}

resource "google_compute_firewall" "ssh_firewall" {
  project     = google_project.administrator_project.project_id
  name        = "allow-to-${lower(var.name)}-tcp-22"
  description = "Allow TCP port 22 to \"${lower(var.name)}\" tagged instances."

  network   = google_compute_network.administrator_network.id
  direction = "INGRESS"
  priority  = 10

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [lower(var.name)]
}

resource "google_folder" "workspace_folder" {
  display_name = join(" ", concat(local.workspace_name, ["Folder"]))
  parent       = var.folder == null ? data.google_organization.organization.name : join("/", ["folders", var.folder])
}

/*
 *
 *
 *
 *
 *
 *
 *
 *
 *
 */

resource "google_cloud_identity_group" "finops_group" {
  provider = google.cloud_identity

  display_name         = title(join(" ", concat(local.workspace_name, ["FinOps"])))
  description          = "Financial operators at the ${join(" ", local.workspace_name)} level."
  initial_group_config = "WITH_INITIAL_OWNER"

  parent = "customers/C03krtmmy"

  group_key {
    id = "${join("-", local.workspace_name)}-finops@wansho.fr"
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

  display_name         = title(join(" ", concat(local.workspace_name, ["Administrators"])))
  description          = "Administrators at the ${join(" ", local.workspace_name)} level."
  initial_group_config = "WITH_INITIAL_OWNER"

  parent = "customers/C03krtmmy"

  group_key {
    id = "${join("-", local.workspace_name)}-administrators@wansho.fr"
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

  display_name         = title(join(" ", concat(local.workspace_name, ["Policy", "Administrators"])))
  description          = "Policy administrators at the ${join(" ", local.workspace_name)} level."
  initial_group_config = "WITH_INITIAL_OWNER"

  parent = "customers/C03krtmmy"

  group_key {
    id = "${join("-", local.workspace_name)}-policy-administrators@wansho.fr"
  }

  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }

  depends_on = [
    google_project_service.administrator_api["cloudidentity.googleapis.com"]
  ]
}

resource "google_cloud_identity_group_membership" "finops_group_owner" {
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
  roles {
    name = "OWNER"
  }
}

resource "google_cloud_identity_group_membership" "administrators_group_owner" {
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
  roles {
    name = "OWNER"
  }
}

resource "google_cloud_identity_group_membership" "policy_administrators_group_owner" {
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
  roles {
    name = "OWNER"
  }
}

resource "google_cloud_identity_group_membership" "finops_parent_group" {
  provider = google.cloud_identity
  group    = "groups/01yyy98l12yhqe4"

  preferred_member_key {
    id = google_cloud_identity_group.finops_group.group_key[0].id
  }
  roles {
    name = "MEMBER"
  }
}

/*
 *
 *
 *
 *
 *
 *
 *
 */

resource "google_folder_iam_binding" "workspace_folder_administrators" {
  folder = google_folder.workspace_folder.name
  role   = "roles/resourcemanager.folderAdmin"
  members = [
    "serviceAccount:${google_service_account.administrator.email}",
  ]

  depends_on = [
    google_cloud_identity_group_membership.administrators_group_owner
  ]
}

resource "google_folder_iam_binding" "workspace_folder_project_creator" {
  folder = google_folder.workspace_folder.name
  role   = "roles/resourcemanager.projectCreator"
  members = [
    "serviceAccount:${google_service_account.administrator.email}",
  ]

  depends_on = [
    google_cloud_identity_group_membership.administrators_group_owner
  ]
}

resource "google_storage_bucket_iam_binding" "bucket_editor" {
  bucket = google_storage_bucket.administrator_bucket.name
  role   = "roles/storage.objectAdmin"
  members = [
    "serviceAccount:${google_service_account.administrator_secretary.email}",
  ]
}

resource "google_project_iam_binding" "owners" {
  project = google_project.administrator_project.project_id
  role    = "roles/owner"
  members = [
    "serviceAccount:${google_service_account.administrator_secretary.email}"
  ]

  depends_on = [
    google_storage_bucket_iam_binding.bucket_editor,
    google_cloud_identity_group_membership.finops_group_owner,
    google_cloud_identity_group_membership.administrators_group_owner,
    google_cloud_identity_group_membership.policy_administrators_group_owner
  ]
}

resource "google_project_iam_binding" "editors" {
  project = google_project.administrator_project.project_id
  role    = "roles/editor"
  members = [
    "serviceAccount:${google_project.administrator_project.number}@cloudservices.gserviceaccount.com"
  ]
}

resource "google_project_iam_binding" "instance_users" {
  project = google_project.administrator_project.project_id
  role    = "roles/compute.instanceAdmin.v1"
  members = [
    "group:${google_cloud_identity_group.administrators_group.group_key[0].id}"
  ]
}

resource "google_service_account_iam_binding" "administrator_impersonator" {
  service_account_id = google_service_account.administrator.name
  role               = "roles/iam.serviceAccountTokenCreator"

  members = [
    "group:${google_cloud_identity_group.administrators_group.group_key[0].id}",
  ]
}

resource "google_service_account_iam_binding" "administrator_secretary_user" {
  service_account_id = google_service_account.administrator_secretary.name
  role               = "roles/iam.serviceAccountUser"

  members = [
    "group:${google_cloud_identity_group.administrators_group.group_key[0].id}",
  ]
}

resource "google_service_account_iam_binding" "policy_administrator_impersonator" {
  service_account_id = google_service_account.policy_administrator.name
  role               = "roles/iam.serviceAccountTokenCreator"

  members = [
    "group:${google_cloud_identity_group.policy_administrators_group.group_key[0].id}",
  ]
}

resource "google_service_account_iam_binding" "finops_impersonator" {
  service_account_id = google_service_account.finops.name
  role               = "roles/iam.serviceAccountTokenCreator"

  members = [
    "group:${google_cloud_identity_group.finops_group.group_key[0].id}",
    "serviceAccount:${google_service_account.administrator.email}",
  ]
}

// How to update the workspace

// How to delete the workspace