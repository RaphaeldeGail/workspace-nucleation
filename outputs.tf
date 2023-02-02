output "root_project_id" {
  value       = google_project.root_project.project_id
  description = "ID of the root project"
  sensitive   = false
}