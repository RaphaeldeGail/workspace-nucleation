<!-- BEGIN_TF_DOCS -->
# workspace\_setup

This module sets up a new **workspace** in a *Google Cloud Organization*.

## Infrastructure description

The code creates a **workspace folder** as well as a **workspace administration project**.

The **workspace administration project** hosts serveral common services, and service accounts, to operate the workspace.

- The **administrator** service account can create any resource in the **workspace folder**.

- The **policy administrator** service account can apply any policy at the **workspace folder** level.

## Organization description

The root structure attemps to create a sub-organization inside the Google Cloud Platform.

Security is then preserved since the original organization is never used apart for creating the root structure.

Below is a simple diagram presenting the structure:

![organizational-structure](docs/organizational-structure.png)
*Figure - Organization diagram for the root structure.*

### Cloud identity

Users and groups

### Cloud organization

IAM and resources

### Root project

Service accounts

### Root folder

Workspaces

## Usage

Before running this code, you should first create a Google Cloud Platform **organization** (see official documentation).

You should also have set up a valid **Billing account** for your organization.

Set the values of the required variables in terraform.tfvars (specifically billing account ID and organization name).

The organization administrator should also claim billing account usage.

Once you are authenticated with terraform cloud, you can run the script:

```bash
./run.sh
```

The root structure is then created.

TODO: Update docs

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
| [google_cloud_identity_group.administrators_group](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_identity_group) | resource |
| [google_cloud_identity_group.finops_group](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_identity_group) | resource |
| [google_cloud_identity_group.policy_administrators_group](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_identity_group) | resource |
| [google_cloud_identity_group_membership.administrators_group_manager](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_identity_group_membership) | resource |
| [google_cloud_identity_group_membership.finops_group_manager](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_identity_group_membership) | resource |
| [google_cloud_identity_group_membership.policy_administrators_group_manager](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_identity_group_membership) | resource |
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
| [google_iam_policy.administrators_impersonation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |
| [google_iam_policy.billing_management](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |
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
| builder\_account | E-mail of the workspace builder service account. | `string` | n/a |
| credentials | The service account credentials. | `string` | n/a |
| organization | Name of the organization hosting the workspace. | `string` | n/a |
| region | Geographical *region* for Google Cloud Platform. | `string` | n/a |
| team | List of team members by roles, *administrator*, *policy\_administrator* and *finops*. | ```object({ administrators = list(string) policy_administrators = list(string) finops = list(string) })``` | n/a |

## Outputs

| Name | Description |
|------|-------------|
| administrator\_project\_id | The ID of the administrator project. |
| workspace\_bucket\_name | The name of the administrator bucket. |
<!-- END_TF_DOCS -->