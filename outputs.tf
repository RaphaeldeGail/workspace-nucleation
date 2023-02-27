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