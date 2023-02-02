output "service_account_email" {
  value       = google_service_account.service_account.email
  description = "Name of the service account as an email address."
  sensitive   = false
}

output "service_account_name" {
  value       = google_service_account.service_account.name
  description = "Name of the service account."
  sensitive   = false
}