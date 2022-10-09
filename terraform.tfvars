billing_account = "Wansho billing account"
organization    = "wansho.fr"
location        = "EU"
region          = "europe-west1"
service_accounts = {
  org_policy_admin = {
    description = "Administrator of organization policies."
    roles       = ["orgpolicy.policyAdmin", "resourcemanager.organizationViewer"]
  }
  project_creator = {
    description = "Creator of projects directly linked to the organization."
    roles       = ["resourcemanager.organizationViewer"]
  }
}