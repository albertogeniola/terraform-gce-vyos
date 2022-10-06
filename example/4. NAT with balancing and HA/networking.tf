# Define an external VPC
resource "google_compute_network" "vyos_external_vpc" {
  name                      = "vyos-external-vpc"
  project                   = var.project_id 
  auto_create_subnetworks   = false
}

resource "google_compute_subnetwork" "vyos_external_subnet" {
  region                    = var.region
  name                      = "vyos-external-subnet"
  project                   = var.project_id 
  network                   = google_compute_network.vyos_external_vpc.self_link
  ip_cidr_range             = local.external_subnet_cidr
  private_ip_google_access  = true  
}

# Define an internal VPC
resource "google_compute_network" "vyos_internal_vpc" {
  name                      = "vyos-internal-vpc"
  project                   = var.project_id 
  auto_create_subnetworks   = false
}

resource "google_compute_subnetwork" "vyos_internal_subnet" {
  region                    = var.region
  name                      = "vyos-internal-subnet"
  project                   = var.project_id 
  network                   = google_compute_network.vyos_internal_vpc.self_link
  ip_cidr_range             = local.internal_subnet_cidr
  private_ip_google_access  = true  
}

# Enable firewall rules for nat access
resource "google_compute_firewall" "proxy_internal_vms" {
  project       = var.project_id 
  name          = "fw-inbound-nat-internal"
  network       = google_compute_network.vyos_internal_vpc.self_link
  source_ranges = [local.internal_subnet_cidr]
  target_service_accounts = [module.vyos_instance_1.sa_email, module.vyos_instance_2.sa_email]
  allow {
    protocol  = "tcp"
  }
  allow {
    protocol  = "udp"
  }
}

# Enable firewall rules for SSH access for the internal VM
resource "google_compute_firewall" "ssh_iap_internal_vms" {
  project       = var.project_id 
  name          = "fw-inbound-iap-ssh"
  network       = google_compute_network.vyos_internal_vpc.self_link
  target_tags   = [local.allow_iap_ssh_inbound_tag]
  source_ranges = local.iap_cidrs
  allow {
    protocol  = "tcp"
    ports     = [ 22 ]
  }
}

# Enable ilb health-checks
resource "google_compute_firewall" "ilb_tcp_health_checks" {
  project       = var.project_id 
  name          = "fw-inbound-ilb-hc"
  network       = google_compute_network.vyos_internal_vpc.self_link
  target_service_accounts = [module.vyos_instance_1.sa_email, module.vyos_instance_2.sa_email]
  source_ranges = local.ilb_hc_cidrs
  allow {
    protocol  = "tcp"
    ports     = [ 22 ] # TODO: change if using a different method to attestate health of the workload
  }
}

# Instance group for the VyOS VMs
resource "google_compute_instance_group" "vyos_web_proxy_unmanaged_primary" {
  project   = var.project_id
  zone      = var.zone_primary
  name      = "vyos-nat-primary"
  
  instances = [
    module.vyos_instance_1.vm_id
  ]
  network = google_compute_network.vyos_external_vpc.self_link
}
resource "google_compute_instance_group" "vyos_web_proxy_unmanaged_secondary" {
  project   = var.project_id
  zone      = var.zone_secondary
  name      = "vyos-nat-secondary"
  
  instances = [
    module.vyos_instance_2.vm_id
  ]
  network = google_compute_network.vyos_external_vpc.self_link
}

# Backend services
resource "google_compute_region_backend_service" "vyos_nat_tcp_backend" {
  project               = var.project_id
  name                  = "vyos-nat-tcp"
  region                = var.region
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"
  timeout_sec           = 10
  health_checks         = [google_compute_region_health_check.vyos_nat_hc.self_link]
  
  # We need to specify the network to be used as backend service, as our VMs do have multiple NICs
  #  and we want to load-balance on the secondary NIC (internal), which is connected to the internal
  #  vpc.
  network               = google_compute_network.vyos_internal_vpc.self_link 
  
  backend {
    group = google_compute_instance_group.vyos_web_proxy_unmanaged_primary.self_link
    balancing_mode  = "CONNECTION"
  }
  backend {
    group = google_compute_instance_group.vyos_web_proxy_unmanaged_secondary.self_link
    balancing_mode  = "CONNECTION"
  }
}
resource "google_compute_region_backend_service" "vyos_nat_udp_backend" {
  project               = var.project_id
  name                  = "vyos-nat-udp"
  region                = var.region
  protocol              = "UDP"
  load_balancing_scheme = "INTERNAL"
  timeout_sec           = 10
  health_checks         = [google_compute_region_health_check.vyos_nat_hc.self_link]
  
  # We need to specify the network to be used as backend service, as our VMs do have multiple NICs
  #  and we want to load-balance on the secondary NIC (internal), which is connected to the internal
  #  vpc.
  network               = google_compute_network.vyos_internal_vpc.self_link 
  
  backend {
    group = google_compute_instance_group.vyos_web_proxy_unmanaged_primary.self_link
    balancing_mode  = "CONNECTION"
  }
  backend {
    group = google_compute_instance_group.vyos_web_proxy_unmanaged_secondary.self_link
    balancing_mode  = "CONNECTION"
  }
}

# Health Checks for the backend service
resource "google_compute_region_health_check" "vyos_nat_hc" {
  project             = var.project_id
  region              = var.region
  name                = "vyos-nat-hc"
  log_config {
    enable = true
  }
  tcp_health_check {
    port = 22 # TODO: use an HTTP HC instead (vyos apis?)
  }
}

# Forwarding rule for VyOS ILB
resource "google_compute_forwarding_rule" "nat_tcp_forwarding" {
  project               = var.project_id
  name                  = "nat-tcp-ilb-forwarding-rule"
  region                = var.region
  depends_on            = [google_compute_subnetwork.vyos_internal_subnet]
  ip_address            = local.proxy_ilb_address_tcp
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL"
  all_ports             = true
  backend_service       = google_compute_region_backend_service.vyos_nat_tcp_backend.self_link
  
  network               = google_compute_network.vyos_internal_vpc.self_link
  subnetwork            = google_compute_subnetwork.vyos_internal_subnet.self_link
}
resource "google_compute_forwarding_rule" "nat_udp_forwarding" {
  project               = var.project_id
  name                  = "nat-udp-ilb-forwarding-rule"
  region                = var.region
  depends_on            = [google_compute_subnetwork.vyos_internal_subnet]
  ip_address            = local.proxy_ilb_address_udp
  ip_protocol           = "UDP"
  load_balancing_scheme = "INTERNAL"
  all_ports             = true
  backend_service       = google_compute_region_backend_service.vyos_nat_udp_backend.self_link
  
  network               = google_compute_network.vyos_internal_vpc.self_link
  subnetwork            = google_compute_subnetwork.vyos_internal_subnet.self_link
}

# Routing traffic to the NAT instances via ILBs
# Default route for internal VPC
resource "google_compute_route" "default_tcp_ilb_route" {
  project     = var.project_id
  name        = "default-route-to-vyos-nat-tcp"
  dest_range  = "0.0.0.0/0"
  network     = google_compute_network.vyos_internal_vpc.self_link
  next_hop_ilb = google_compute_forwarding_rule.nat_tcp_forwarding.self_link
  priority    = 100
}

locals {
  external_subnet_cidr        = "10.0.0.0/16"
  internal_subnet_cidr        = "10.10.0.0/16"
  allow_iap_ssh_inbound_tag   = "ssh-iap"
  iap_cidrs                   = ["35.235.240.0/20"]
  proxy_ilb_address_tcp       = cidrhost(local.internal_subnet_cidr, 3)
  proxy_ilb_address_udp       = cidrhost(local.internal_subnet_cidr, 4)
  external_vyos_1_ip          = cidrhost(local.external_subnet_cidr, 5)
  external_vyos_2_ip          = cidrhost(local.external_subnet_cidr, 6)
  internal_vyos_1_ip          = cidrhost(local.internal_subnet_cidr, 5)
  internal_vyos_2_ip          = cidrhost(local.internal_subnet_cidr, 6)
  
  internal_test_vm_ip         = cidrhost(local.internal_subnet_cidr, 7)

  ilb_hc_cidrs       = ["35.191.0.0/16", "130.211.0.0/22"]
}