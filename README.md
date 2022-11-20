<!-- BEGIN_TF_DOCS -->
# Root

This module sets up a root project in a Google Cloud organization.

Along with its root service account, this project bare full access to the organization and is maximally critical as such.

This code should be used against with application-default credentials of an admin user.

The user should also claim billing account usage to bind the root project with.

A Google Storage bucket is also created to store any critical files related to the root project.

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.1.2 |
| google | ~> 4.5.0 |
| random | ~> 3.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| service\_account | ./modules/service account | n/a |

## Resources

| Name | Type |
|------|------|
| [google_folder.root_folder](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder) | resource |
| [google_folder_iam_member.root_folder_admins](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder_iam_member) | resource |
| [google_folder_iam_member.root_folder_project_creator](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder_iam_member) | resource |
| [google_project.root_project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project) | resource |
| [google_project_service.service](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_storage_bucket.root_bucket](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [random_string.random](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [google_organization.org](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/organization) | data source |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| billing\_account | The ID of the billing account used for the workspace. | `string` | n/a |
| location | Geographical *location* for Google Cloud Platform. | `string` | n/a |
| organization | Name of the organization hosting the workspace. | `string` | n/a |
| region | Geographical *region* for Google Cloud Platform. | `string` | n/a |
| service\_accounts | List of service accounts along with their privileges. Only underscore, digits and lowercase letters are allowed for the key. | ```map(object({ description = string roles = list(string) }))``` | n/a |

## Outputs

| Name | Description |
|------|-------------|
| root\_bucket\_name | Name of the root storage bucket |
| root\_project\_id | ID of the root project |
<!-- END_TF_DOCS -->