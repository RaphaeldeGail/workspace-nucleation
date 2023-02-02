<!-- BEGIN_TF_DOCS -->
# Service Account

This module creates a service account as an object.

Organization roles are then applied for the account.

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.1.2 |
| google | ~> 4.5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_organization_iam_member.organization_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_member) | resource |
| [google_service_account.service_account](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_key.service_account_key](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_key) | resource |
| [google_storage_bucket_iam_member.bucket_editor](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [google_storage_bucket_object.service_account_key_backup](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| bucket\_name | Name of the bucket for service account key backup. If a non-null value is given, a private key for the service account will be created and upload to the bucket. | `string` | `null` |
| description | Optional description of the service account. | `string` | n/a |
| full\_name | Name of the service account. May only contain underscore, digits and lowercase letters. | `string` | n/a |
| org\_id | The organization ID as a string. | `string` | n/a |
| project\_id | ID of the project hosting the service account. | `string` | n/a |
| roles | A list of organization-scoped roles for the service account. | `list(string)` | n/a |

## Outputs

| Name | Description |
|------|-------------|
| service\_account\_email | Name of the service account as an email address. |
| service\_account\_name | Name of the service account. |
<!-- END_TF_DOCS -->