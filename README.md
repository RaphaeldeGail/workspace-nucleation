<!-- BEGIN_TF_DOCS -->
# workspace\_nucleation

This script sets up a new **workspace** in a *Google Cloud Organization*.
To get started, please see the [docs folder](docs/README.md).

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
| [google_billing_budget.workspace_budget](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/billing_budget) | resource |
| [google_dns_managed_zone.workspace_dns_zone](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_managed_zone) | resource |
| [google_dns_managed_zone_iam_policy.dns_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dns_managed_zone_iam_policy) | resource |
| [google_folder.workspace_folder](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder) | resource |
| [google_folder_iam_member.folder_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder_iam_member) | resource |
| [google_folder_iam_member.folder_admin_viewer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder_iam_member) | resource |
| [google_folder_iam_member.folder_finops_viewer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder_iam_member) | resource |
| [google_folder_iam_member.folder_policy_viewer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder_iam_member) | resource |
| [google_folder_iam_member.folder_project_creator](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder_iam_member) | resource |
| [google_kms_crypto_key.symmetric_key](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key) | resource |
| [google_kms_crypto_key_iam_policy.kms_key_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_policy) | resource |
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
| [google_tags_tag_value_iam_binding.tag_user](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_value_iam_binding) | resource |
| [google_tags_tag_value_iam_binding.tag_viewer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_value_iam_binding) | resource |
| [random_string.workspace_uid](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [google_dns_keys.workspace_dns_keys](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/dns_keys) | data source |
| [google_iam_policy.administrators_impersonation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |
| [google_iam_policy.billing_management](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |
| [google_iam_policy.dns_management](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |
| [google_iam_policy.kms_key_usage](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |
| [google_iam_policy.ownership](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |
| [google_iam_policy.policy_administrators_impersonation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |
| [google_iam_policy.storage_management](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |
| [google_storage_project_service_account.gcs_account](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/storage_project_service_account) | data source |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| admin\_group | Email for administrators group. | `string` | n/a |
| billing\_account | The ID of the billing account used for the workspace. | `string` | n/a |
| budget\_allowed | The monthly amount allowed for the workspace. Must be an integer. | `number` | n/a |
| customer\_directory | The ID of the Google Cloud Identity directory. | `string` | n/a |
| finops\_group | Email for finops group. | `string` | n/a |
| organization | Name, or domain, of the organization hosting the workspace. | `string` | n/a |
| policy\_group | Email for policy administrators group. | `string` | n/a |
| project | The ID of the root project for the organization. Used to create workspaces. | `string` | n/a |
| region | Geographical *region* for Google Cloud Platform. | `string` | n/a |
| workspaces\_folder | The ID of the "Workspaces" folder that contains all subsequent workspaces. | `string` | n/a |
| workspaces\_tag\_key | The ID of "workspace" tag key. | `string` | n/a |

## Outputs

| Name | Description |
|------|-------------|
| administrator\_project\_id | The ID of the administrator project. |
| dns\_registrar\_setup | The DNS records to add to the registrar of the domain to setup the DNS subnzone, with DNSsec on. |
| workspace\_bucket\_name | The name of the administrator bucket. |
<!-- END_TF_DOCS -->