output "vm_id" {
  description = "VyOS instance ID"
  value       = google_compute_instance.vyos.self_link
}

output "sa_email" {
  description = "VyOS instance Service Account"
  value       = google_service_account.vyos_compute_sa.email
}