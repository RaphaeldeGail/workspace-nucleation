output "administrator_project_id" {
  value       = google_project.administrator_project.project_id
  description = "The ID of the administrator project."
  sensitive   = false
}

output "workspace_bucket_name" {
  value       = google_storage_bucket.administrator_bucket.name
  description = "The name of the administrator bucket."
  sensitive   = false
}

output "dns_registrar_setup" {
  value = {
    domain_name  = google_dns_managed_zone.workspace_dns_zone.dns_name
    name_servers = google_dns_managed_zone.workspace_dns_zone.name_servers
    ds_record    = data.google_dns_keys.workspace_dns_keys.key_signing_keys[0].ds_record
  }
  description = "The DNS records to add to the registrar of the domain to setup the DNS subzone, with DNSsec on."
  sensitive   = false
}