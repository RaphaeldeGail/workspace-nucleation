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

provider "google" {
  /**
   * This is a workaround to manage group membership as it requires either a service account (none created yet) or a billing project declare for the client.
   * We create an alternative provider which points to the root project for the billing project.
   * The alternative provider avoids cyclic dependencies since it is only called after the root project has been created.
   */
  region = var.region

  alias                 = "cloud_identity"
  user_project_override = true
  billing_project       = google_project.root_project.project_id
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
    "cloudidentity.googleapis.com",
    "compute.googleapis.com"
  ]
  root_name       = "root"
  project_name    = local.root ? ["root"] : ["workspace", title(var.name), "v${var.maj_version}"]
  base_cidr_block = "10.1.0.0/27"
  root            = (var.folder == null) && (var.organization != null) ? true : false
  index_length    = local.root ? 16 : 4

  labels = local.root ? { root = true } : { root = false, workspace = tostring(var.name), maj_version = tostring(var.maj_version) }
}

data "google_organization" "org" {
  count = local.root ? 1 : 0

  domain = var.organization
}

resource "random_string" "random" {
  /** 
   * Random string with only lowercase letters and integers.
   * Will be used to generate the root project ID and root bucket
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

resource "google_project" "root_project" {
  /**
   * Root project of the organization.
   */
  name            = join(" ", local.project_name)
  project_id      = join("-", concat(local.project_name, [random_string.random.result]))
  org_id          = local.root ? data.google_organization.org[0].org_id : null
  billing_account = var.billing_account
  folder_id       = var.folder
  labels          = local.labels
  // Org policies are not set up at this point so we rely on the auto_create_network feature to remove the root project default network.
  auto_create_network = local.root ? false : null
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

module "service_account" {
  source   = "./modules/service account"
  for_each = var.service_accounts

  org_id      = data.google_organization.org[0].org_id
  full_name   = each.key
  description = each.value.description
  project_id  = google_project.root_project.project_id
  bucket_name = null
  roles       = each.value.roles
}

resource "google_storage_bucket" "workspace_bucket" {
  name                        = google_project.root_project.project_id
  location                    = var.region
  project                     = google_project.root_project.project_id
  force_destroy               = false
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  labels = local.labels
}

resource "google_service_account" "workspace_owner" {
  account_id   = lower(join("-", concat(local.project_name, ["0"])))
  display_name = title(join(" ", concat(local.project_name, ["Service", "Account"])))
  description  = "This service account has full acces to folder ${google_folder.root_folder.display_name} with numeric ID: ${google_folder.root_folder.id}"
  project      = google_project.root_project.project_id
}

resource "google_folder" "root_folder" {
  display_name = title(join(" ", concat(local.project_name, ["folder"])))
  parent       = local.root ? data.google_organization.org[0].name : join("/", ["folders", var.folder])
}

resource "google_folder_iam_binding" "root_folder_admins" {
  folder = google_folder.root_folder.name
  role   = "roles/resourcemanager.folderAdmin"
  members = [
    "serviceAccount:${google_service_account.workspace_owner.email}",
  ]
}

resource "google_folder_iam_binding" "root_folder_project_creator" {
  folder = google_folder.root_folder.name
  role   = "roles/resourcemanager.projectCreator"
  members = [
    "serviceAccount:${google_service_account.workspace_owner.email}",
  ]
}

resource "google_storage_bucket_iam_binding" "workspace_bucket_editors" {
  bucket = google_storage_bucket.workspace_bucket.name
  role   = "roles/storage.admin"
  members = [
    "serviceAccount:${google_service_account.workspace_owner.email}",
  ]
}

resource "google_compute_network" "network" {
  project     = google_project.root_project.project_id
  name        = "${local.root_name}-network"
  description = "Network for administrative usage."

  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  delete_default_routes_on_create = true

  depends_on = [
    google_project_service.service["compute.googleapis.com"]
  ]
}

resource "google_compute_subnetwork" "subnetwork" {
  project     = google_project.root_project.project_id
  name        = "${local.root_name}-subnet"
  description = "Subnetwork hosting instances for administrative usage."

  network       = google_compute_network.network.id
  ip_cidr_range = cidrsubnet(local.base_cidr_block, 2, 0)
}

resource "google_compute_route" "default_route" {
  project     = google_project.root_project.project_id
  name        = join("-", ["from", local.root_name, "to", "internet"])
  description = "Default route from the ${local.root_name} network to the internet"

  network          = google_compute_network.network.name
  dest_range       = "0.0.0.0/0"
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
  tags             = [local.root_name]
}

resource "google_compute_firewall" "firewall" {
  project     = google_project.root_project.project_id
  name        = join("-", ["allow", "to", local.root_name, "tcp", "22"])
  description = "Allow requests from the internet to the administrative instances."

  network   = google_compute_network.network.id
  direction = "INGRESS"
  priority  = 10

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [local.root_name]
}

resource "google_project_iam_binding" "no_owners" {
  project = google_project.root_project.project_id
  role    = "roles/owner"
  members = ["group:org-admins@${var.organization}", "serviceAccount:${module.service_account["organization_secretary"].service_account_email}"]
}

resource "google_project_iam_binding" "no_editors" {
  project = google_project.root_project.project_id
  role    = "roles/editor"
  members = ["serviceAccount:${google_project.root_project.number}@cloudservices.gserviceaccount.com"]
}

resource "google_cloud_identity_group_membership" "workspace_group_owner" {
  provider = google.cloud_identity
  group    = "groups/02xcytpi1smdo70"

  preferred_member_key {
    id = module.service_account["project_creator"].service_account_email
  }
  roles {
    name = "MEMBER"
  }
  roles {
    name = "MANAGER"
  }

  depends_on = [
    google_project.root_project,
  ]
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

  display_name         = title(join(" ", concat(local.project_name, ["FinOps"])))
  description          = "Financial operators at the ${join(" ", local.project_name)} level."
  initial_group_config = "WITH_INITIAL_OWNER"

  parent = "customers/C03krtmmy"

  group_key {
    id = "${join("-", local.project_name)}-finops@wansho.fr"
  }

  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }

  depends_on = [
    google_project.root_project,
  ]
}

resource "google_cloud_identity_group" "admins_group" {
  provider = google.cloud_identity

  display_name         = title(join(" ", concat(local.project_name, ["Admins"])))
  description          = "Administrators at the ${join(" ", local.project_name)} level."
  initial_group_config = "WITH_INITIAL_OWNER"

  parent = "customers/C03krtmmy"

  group_key {
    id = "${join("-", local.project_name)}-admins@wansho.fr"
  }

  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }

  depends_on = [
    google_project.root_project,
  ]
}

resource "google_cloud_identity_group" "policy_admins_group" {
  provider = google.cloud_identity

  display_name         = title(join(" ", concat(local.project_name, ["Policy", "Admins"])))
  description          = "Policy administrators at the ${join(" ", local.project_name)} level."
  initial_group_config = "WITH_INITIAL_OWNER"

  parent = "customers/C03krtmmy"

  group_key {
    id = "${join("-", local.project_name)}-policy-admins@wansho.fr"
  }

  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }

  depends_on = [
    google_project.root_project,
  ]
}