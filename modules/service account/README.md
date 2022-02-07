<!-- BEGIN_TF_DOCS -->
# Service Account

This module creates a service account along with its privileges.

A service account authentication key is also bound and pushed to a google storage bucket.

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
| [google_organization_iam_member.service_acount_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_member) | resource |
| [google_service_account.service_account](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_key.service_account_key](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_key) | resource |
| [google_storage_bucket_object.service_account_key_backup](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_object) | resource |
| [google_project.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| bucket\_name | Name of the bucket for service account key backup. | `string` | n/a |
| description | Optional description of the service account. | `string` | n/a |
| full\_name | Name of the service account. May only contain underscore, digits and lowercase letters. | `string` | n/a |
| project\_id | ID of the project hosting the service account. | `string` | n/a |
| role | role bound to the service account. | `string` | n/a |

## Outputs

No outputs.
<!-- END_TF_DOCS -->