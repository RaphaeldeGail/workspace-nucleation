<!-- BEGIN_TF_DOCS -->
# workspace\_setup

This module sets up a new **workspace** in a *Google Cloud Organization*.

## Introduction

A **workspace** is an infrastructure concept for developers to autonomously manage their infrastrucure resources and environments.

### What is a workspace?

A **workspace** is a dedicated set of cloud resources for a particular project.
It is isolated from other workspaces, and relies on specific common services, such as DNS zone, GCS bucket, etc.

### What is the use of a workspace?

Within a workspace, a team can create infrastructure resources in different environments with full autonomy.
The resources are bound to a minimal set of common services (DNS zone, etc.) to ensure correct integration with other projects and the outer world.

### How do I use a workspace?

Once your workspace has been delivered, you can use it to create your own GCP projects within your own folder.
You can create almost any resources in those projects and group them as you need (per environments, per domain, etc.).
You can also use the common services of the workspace to manage resources that span among the whole workspace, such as *compute images* for servers among all environments, etc.

### How do I create a workspace?

To create a workspace, you will need a name for the workspace (only lowercase letters), and a list of team members for the three default groups: admins, policy-admins and finops.
You also need to use this code and follow the instructions below.

## Workspace description

Below is a comprehensive description of a workspace.

### Workspace organization

A workspace is made of three main parts:

- the workspace folder where the team can create all the projects needed for their project,
- the ADM (administration) project, where the team can manage the workspace and its common services,
- three Google groups, where team members will be added, and which control the workspace.

The three Google groups created are:

- The *FinOps Group*, with access to billing information about the workspace,
- The *Administrators Group*, with access to the workspace,
- The *Policy Administrators Group*, with access to policies for the workspace folder.

Both the workspace folder and the ADM project belong to the organization level (no parent folder).
The workspace folder is initially empty and left to the team to use for their project.
The ADM project is initially setup with several services:

- Service accounts to manipulate the workspace,
- a GCS bucket to store data across the workspace, for instance some configuration files that belong to all the environments,
- Access to compute image storage,
- a keyring to encrypt the GCS data with a dedicated key.

The service accounts in the ADM project are:

- the *administrator* service account, with read/write over the workspace, and the workspace folder specifically,
- the *policy-administrator* service account, with management rights for policies over the workspace folder.

On top of these resources, the workspace is also tagged at several level:

- The workspace folder is tagged with the *workspace* key and the **workspace name** as the value,
- the ADM project and the GCS bucket are identically tagged.

Below is a simple diagram presenting the organization:

![organizational-structure](docs/organizational-structure.svg)
*Figure - Organization diagram for the workspace structure.*

### Workspace management

The workspace is mainly managed by service accounts, with read/write access to resources.
Google groups have mainly read access, but can also impersonate the service accounts.

The *administrator* service account is the owner of the workspace folder and thus can create any resource in it.
It has also administrative rights to the GCS bucket and the compute image storage.

The *Administrators Group* can impersonate the *administrator* service account.
The *Policy Administrators Group* can impersonate the *policy-administrator* service account.

Below is a simple diagram presenting the organization:

![functional-structure](docs/functional-structure.svg)
*Figure - Functional diagram for the workspace structure -*
*The yellow blocks represent IAM permissions bound to a user on a resource.*

On top of the permissions within the team, the organization administrators remain the owners of the ADM project and of the workspace folder, by inheritance.
Only the *builder* service account can create a workspace.
Only an organization administrator can delete a workspace.

## Repository presentation

TODO: HERE

### Repository structure

*What is in this repo?*

### Repository usage

*How do I use this repo to create a workspace?*

- Terraform Cloud config (organization, workspace, variables)
- Terraform client config
- Google Cloud Organization
- Root project (Root setup)
- builder account with permissions
- secretary account

Before running this code, you should first create a Google Cloud Platform **organization** (see official documentation).

Once you are authenticated with terraform cloud, you can run the script:

```bash
./run.sh
```

The workspace structure is then created.

TODO: DNSSEC config

***

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.2.0 |
| google | ~> 4.53.1 |
| random | ~> 3.1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_billing_account_iam_policy.billing_account_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/billing_account_iam_policy) | resource |
| [google_billing_budget.workspace_budget](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/billing_budget) | resource |
| [google_cloud_identity_group.administrators_group](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_identity_group) | resource |
| [google_cloud_identity_group.finops_group](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_identity_group) | resource |
| [google_cloud_identity_group.policy_administrators_group](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_identity_group) | resource |
| [google_cloud_identity_group_membership.administrators_group_manager](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_identity_group_membership) | resource |
| [google_cloud_identity_group_membership.finops_group_manager](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_identity_group_membership) | resource |
| [google_cloud_identity_group_membership.policy_administrators_group_manager](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_identity_group_membership) | resource |
| [google_dns_managed_zone.workspace_dns_zone](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_managed_zone) | resource |
| [google_dns_managed_zone_iam_policy.dns_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_managed_zone_iam_policy) | resource |
| [google_dns_record_set.workspace_ds_record](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set) | resource |
| [google_dns_record_set.workspace_ns_record](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_record_set) | resource |
| [google_folder.workspace_folder](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder) | resource |
| [google_folder_iam_policy.folder_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder_iam_policy) | resource |
| [google_kms_crypto_key.symmetric_key](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key) | resource |
| [google_kms_crypto_key_iam_policy.kms_key_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_policy) | resource |
| [google_kms_crypto_key_version.key_instance](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_version) | resource |
| [google_kms_key_ring.workspace_keyring](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_key_ring) | resource |
| [google_project.administrator_project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project) | resource |
| [google_project_iam_custom_role.image_manager_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role) | resource |
| [google_project_iam_policy.project_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_policy) | resource |
| [google_project_service.administrator_api](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_service_account.administrator](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account.policy_administrator](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_iam_policy.administrator_service_account_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_policy) | resource |
| [google_service_account_iam_policy.policy_administrator_service_account_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_policy) | resource |
| [google_storage_bucket.administrator_bucket](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_iam_policy.bucket_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_policy) | resource |
| [google_tags_location_tag_binding.bucket_tag_binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_location_tag_binding) | resource |
| [google_tags_tag_binding.workspace_folder_tag_binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_binding) | resource |
| [google_tags_tag_binding.workspace_tag_binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_binding) | resource |
| [google_tags_tag_value.workspace_tag_value](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_value) | resource |
| [google_tags_tag_value_iam_policy.tags_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_value_iam_policy) | resource |
| [random_string.workspace_uid](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [google_dns_keys.workspace_dns_keys](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/dns_keys) | data source |
| [google_dns_managed_zone.workspaces_zone](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/dns_managed_zone) | data source |
| [google_iam_policy.administrators_impersonation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |
| [google_iam_policy.billing_management](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |
| [google_iam_policy.dns_management](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |
| [google_iam_policy.kms_key_usage](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |
| [google_iam_policy.management](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |
| [google_iam_policy.ownership](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |
| [google_iam_policy.policy_administrators_impersonation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |
| [google_iam_policy.storage_management](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |
| [google_iam_policy.tags_usage](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |
| [google_organization.organization](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/organization) | data source |
| [google_tags_tag_key.workspace_tag_key](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/tags_tag_key) | data source |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| billing\_account | The ID of the billing account used for the workspace. | `string` | n/a |
| builder\_account | The e-mail of the service account used to build the workspace. | `string` | n/a |
| organization | Name of the organization hosting the workspace. | `string` | n/a |
| organization\_administrators\_group | The name of the Google group for organization administrators. The name should not contain the organization @domainName. | `string` | n/a |
| project | The ID of the root project for the organization. Used to create workspaces. | `string` | n/a |
| region | Geographical *region* for Google Cloud Platform. | `string` | n/a |
| team | List of team members by roles, *administrator*, *policy\_administrator* and *finops*. | ```object({ administrators = list(string) policy_administrators = list(string) finops = list(string) })``` | n/a |

## Outputs

| Name | Description |
|------|-------------|
| administrator\_project\_id | The ID of the administrator project. |
| workspace\_bucket\_name | The name of the administrator bucket. |
<!-- END_TF_DOCS -->