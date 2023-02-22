<!-- BEGIN_TF_DOCS -->
# Root

This module sets up the root structure in a Google Cloud organization.

## Infrastructure description

The code creates a root folder as well as a root Google Cloud project, hosting several critical service accounts for the organization.

The **project creator** service account can create any project inside the root folder.

The **org policy** service account can apply any policy at the organization level.

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

This code should be used against with **application-default** credentials of an **Organization Administrator**.

In order to login with application-default, type:
```bash
gcloud auth application-default login
```
You will be redirected to a web login interface.

The organization administrator should also claim billing account usage.

Once you are authenticated with application-default credentials, you can run the script:
```bash
./run.sh
```

The root structure is then created.

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.1.2 |
| google | ~> 4.5.0 |
| random | ~> 3.1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_cloud_identity_group.administrators_group](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_identity_group) | resource |
| [google_cloud_identity_group.finops_group](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_identity_group) | resource |
| [google_cloud_identity_group.policy_administrators_group](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_identity_group) | resource |
| [google_cloud_identity_group_membership.administrators_group_manager](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_identity_group_membership) | resource |
| [google_cloud_identity_group_membership.finops_group_manager](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_identity_group_membership) | resource |
| [google_cloud_identity_group_membership.finops_group_member](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_identity_group_membership) | resource |
| [google_cloud_identity_group_membership.parent_finops_group_member](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_identity_group_membership) | resource |
| [google_cloud_identity_group_membership.policy_administrators_group_manager](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_identity_group_membership) | resource |
| [google_folder.workspace_folder](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder) | resource |
| [google_folder_iam_policy.folder_access](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder_iam_policy) | resource |
| [google_project.administrator_project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project) | resource |
| [google_project_iam_custom_role.image_manager_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role) | resource |
| [google_project_iam_policy.project_access](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_policy) | resource |
| [google_project_service.administrator_api](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_service_account.administrator](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account.policy_administrator](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_iam_policy.administrator_access](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_policy) | resource |
| [google_service_account_iam_policy.policy_administrator_access](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_policy) | resource |
| [google_storage_bucket.administrator_bucket](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_iam_policy.bucket_access](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_policy) | resource |
| [random_string.workspace_uid](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [google_active_folder.parent_folder](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/active_folder) | data source |
| [google_cloud_identity_groups.parent_groups](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/cloud_identity_groups) | data source |
| [google_iam_policy.administrator_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |
| [google_iam_policy.bucket_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |
| [google_iam_policy.folder_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |
| [google_iam_policy.policy_administrator_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |
| [google_iam_policy.project_admin](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/iam_policy) | data source |
| [google_organization.organization](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/organization) | data source |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| billing\_account | The ID of the billing account used for the workspace. | `string` | n/a |
| maj\_version | Major version of the new workspace. Defaults to 0. | `number` | `0` |
| name | Name of the new workspace. | `string` | `"root"` |
| organization | Name of the organization hosting the workspace. | `string` | `null` |
| parent | The name of the parent workspace in the form of *{name}-v{version}*. | `string` | `null` |
| region | Geographical *region* for Google Cloud Platform. | `string` | n/a |
| team | List of team members by roles, *administrator*, *policy\_administrator* and *finops*. | ```object({ administrators = list(string) policy_administrators = list(string) finops = list(string) })``` | n/a |

## Outputs

| Name | Description |
|------|-------------|
| administrator\_project\_id | ID of the administrator project. |
<!-- END_TF_DOCS -->