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

### Repository structure

The reposiotry contains the terraform script to generate a workspace belonging to a Google Cloud Organization.
The terraform files organizes in a regular fashion with *main.tf*, *variables.tf* and *outputs.tf*.

Along with the standard terraform files is the terraform-docs configuration file, used to generate this README.
Last, the *docs* repository stores every diagrams needed for the documentation.

### Repository usage

In order to create a workspace with the terraform script, you will need the following:

1. an access to a Google Cloud Organization
1. Root project (Root setup)
1. an access to a Google Cloud service account with the following rights:
1. Terraform client config (no configuration is provided here for terraform backend, etc.)
1. builder account with permissions:
   - billing.accounts.get
   - billing.accounts.getIamPolicy
   - billing.accounts.list
   - billing.accounts.setIamPolicy
   - billing.resourceAssociations.create
   - billing.resourceAssociations.delete
   - billing.resourceAssociations.list
   - cloudkms.cryptoKeys.create
   - cloudkms.cryptoKeys.get
   - cloudkms.cryptoKeys.getIamPolicy
   - cloudkms.cryptoKeys.list
   - cloudkms.cryptoKeys.setIamPolicy
   - cloudkms.cryptoKeys.update
   - cloudkms.keyRings.create
   - cloudkms.keyRings.createTagBinding
   - cloudkms.keyRings.deleteTagBinding
   - cloudkms.keyRings.get
   - cloudkms.keyRings.getIamPolicy
   - cloudkms.keyRings.list
   - cloudkms.keyRings.listEffectiveTags
   - cloudkms.keyRings.listTagBindings
   - cloudkms.keyRings.setIamPolicy
   - cloudkms.locations.generateRandomBytes
   - cloudkms.locations.get
   - dns.dnsKeys.get
   - dns.dnsKeys.list
   - dns.managedZoneOperations.get
   - dns.managedZoneOperations.list
   - dns.managedZones.create
   - dns.managedZones.delete
   - dns.managedZones.get
   - dns.managedZones.getIamPolicy
   - dns.managedZones.list
   - dns.managedZones.setIamPolicy
   - dns.managedZones.update
   - iam.serviceAccounts.create
   - iam.serviceAccounts.delete
   - iam.serviceAccounts.get
   - iam.serviceAccounts.getIamPolicy
   - iam.serviceAccounts.list
   - iam.serviceAccounts.setIamPolicy
   - iam.serviceAccounts.undelete
   - iam.serviceAccounts.update
   - orgpolicy.constraints.list
   - orgpolicy.policies.list
   - orgpolicy.policy.get
   - resourcemanager.folders.create
   - resourcemanager.folders.get
   - resourcemanager.folders.getIamPolicy
   - resourcemanager.folders.list
   - resourcemanager.folders.setIamPolicy
   - resourcemanager.hierarchyNodes.createTagBinding
   - resourcemanager.hierarchyNodes.deleteTagBinding
   - resourcemanager.hierarchyNodes.listEffectiveTags
   - resourcemanager.hierarchyNodes.listTagBindings
   - resourcemanager.organizations.get
   - resourcemanager.projects.create
   - resourcemanager.projects.createBillingAssignment
   - resourcemanager.projects.deleteBillingAssignment
   - resourcemanager.projects.get
   - resourcemanager.projects.getIamPolicy
   - resourcemanager.projects.list
   - resourcemanager.projects.setIamPolicy
   - resourcemanager.projects.update
   - resourcemanager.tagHolds.create
   - resourcemanager.tagHolds.delete
   - resourcemanager.tagHolds.list
   - resourcemanager.tagKeys.get
   - resourcemanager.tagKeys.getIamPolicy
   - resourcemanager.tagKeys.list
   - resourcemanager.tagValueBindings.create
   - resourcemanager.tagValueBindings.delete
   - resourcemanager.tagValues.create
   - resourcemanager.tagValues.delete
   - resourcemanager.tagValues.get
   - resourcemanager.tagValues.getIamPolicy
   - resourcemanager.tagValues.list
   - resourcemanager.tagValues.setIamPolicy
   - resourcemanager.tagValues.update
   - storage.buckets.create
   - storage.buckets.createTagBinding
   - storage.buckets.deleteTagBinding
   - storage.buckets.get
   - storage.buckets.getIamPolicy
   - storage.buckets.list
   - storage.buckets.listEffectiveTags
   - storage.buckets.listTagBindings
   - storage.buckets.setIamPolicy
   - storage.buckets.update

Before running this code, you should first create a Google Cloud Platform **organization** (see official documentation).

Once you are authenticated with terraform cloud, you can run the command:

```bash
terraform apply
```

All resources managed by terraform are documented in [terraform/README.md](terraform/README.md).

The workspace structure is then created.

### Documentation generation

You will have to install the terraform-docs utility from [https://terraform-docs.io/](https://terraform-docs.io/)
Then use the following command:

```bash
terraform-docs .
```

in the root of the repository.
The *.terraform-docs.yml* files points to a specific version of terraform-docs but you may change it as needed.

***
