resource "google_compute_firewall" "allow_ssh_iap" {
  for_each = {for index,conf in var.networks_configuration: index => conf if conf.create_iap_ssh_firewall_rule }
  
  project       = each.value.network_project_id
  name          = "fw-ssh-iap-inbound-${var.instance_name}-${each.key}"
  network       = each.value.network

  direction     = "INGRESS"
  source_ranges = local.IAP_RANGES 
  target_service_accounts = [google_service_account.vyos_compute_sa.email]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}