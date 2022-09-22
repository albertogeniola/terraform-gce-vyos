module "vyos_instance" {
    source = "../../module-src"
    
    # Project info
    project_id      = var.project_id
    gcp_region      = var.region
    instance_name   = "my-vyos-instance"

    # Dynamic config
    configuration_bucket_name   = "${var.project_id}-vyos-conf"
    configuration_bucket_path   = "/configuration"
    vyos_configuration_content  = file("vyos.config") # Note: you can use a templatefile function to apply scripting logic to the configuration
                                                      # file and drive some initial parameters via terraform.

    # GCE config
    instance_tier               = "n2-standard-2"
    instance_zone               = var.zone
    instance_vyos_image_name    = "vyos-gce" # ATTENTION! THIS IS THE NAME OF THE VYOS IMAGE IMPORTED FROM THIS REPO.
    instance_vyos_image_region  = "eu"       # ATTENTION! Make sure to use the correct region where the image resides.

    # We want to be able to connect via serial port
    enable_serial_port_connection = true

    # Networking configuration
    networks_configuration = {
      
      # Primary interface
      0 = {
        network_project_id  = var.project_id
        network             = google_compute_network.vyos_external_vpc.self_link
        subnetwork          = google_compute_subnetwork.vyos_external_subnet.self_link
        network_ip          = cidrhost(local.external_subnet_cidr, 3)
        
        assign_external_ip = true
        static_external_ip = null

        # Enable IAP connections on the external interface.
        create_iap_ssh_firewall_rule = true
      },

      # Secondary interface
      1 = {
        network_project_id  = var.project_id
        network             = google_compute_network.vyos_internal_vpc.self_link
        subnetwork          = google_compute_subnetwork.vyos_internal_subnet.self_link
        network_ip          = cidrhost(local.internal_subnet_cidr, 3)

        assign_external_ip = false
        static_external_ip = null

        create_iap_ssh_firewall_rule = false
      }
    }
}

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

locals {
  external_subnet_cidr = "10.0.0.0/16"
  internal_subnet_cidr = "10.10.0.0/16"
}