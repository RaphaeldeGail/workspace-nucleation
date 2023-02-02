billing_account = "018C3B-328C3D-6B7D4F"
organization    = "wansho.fr"
region          = "europe-west1"
service_accounts = {
  org_policy_admin = {
    description = "Administrator of organization policies."
    roles       = ["orgpolicy.policyAdmin", "resourcemanager.organizationViewer"]
  }
  project_creator = {
    description = "Creator of projects directly linked to the root folder."
    roles       = ["resourcemanager.organizationViewer"]
  }
  organization_secretary = {
    description = "Owner of the root project."
    roles       = []
  }
}