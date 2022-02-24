output "service_account_email" {
  value       = google_service_account.service_account.email
  description = "Name of the service account as an email address."
  sensitive   = false
}