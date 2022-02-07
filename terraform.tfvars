billing_account = "Wansho billing account"
organization    = "wansho.fr"
location        = "EU"
region          = "europe-west1"
service_accounts = {
  org_policy_admin = {
    description = "Administrator of organization policies."
    role        = "orgpolicy.policyAdmin"
  }
  project_creator = {
    description = "Creator of projects directly linked to the organization."
    role        = "resourcemanager.projectCreator"
  }
}