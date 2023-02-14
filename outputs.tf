output "administrator_project_id" {
  value       = google_project.administrator_project.project_id
  description = "ID of the administrator project."
  sensitive   = false
}