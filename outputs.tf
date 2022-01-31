output "root_bucket_name" {
  value       = google_storage_bucket.root_bucket.name
  description = "Name of the root storage bucket"
  sensitive   = false
}

output "root_project_id" {
  value       = google_project.root_project.project_id
  description = "ID of the root project"
  sensitive   = false
}