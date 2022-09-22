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

    # Networking configuration
    networks_configuration = [
      # Primary interface
      {
        network     = google_compute_network.vyos_vpc.self_link
        subnetwork  = google_compute_subnetwork.vyos_subnet.self_link
        network_ip  = cidrhost(local.subnet_cidr, 3)

        # Omitting access_config, so no external IP address will be associated with VyOS
        access_config = {
          nat_ip                  = null
          public_ptr_domain_name  = null
          network_tier            = "PREMIUM"
        }
      }
    ]
}

resource "google_compute_network" "vyos_vpc" {
  name                      = "vyos-vpc"
  project                   = var.project_id 
  auto_create_subnetworks   = false
}

resource "google_compute_subnetwork" "vyos_subnet" {
  region                    = var.region
  name                      = "vyos-subnet"
  project                   = var.project_id 
  network                   = google_compute_network.vyos_vpc.self_link
  ip_cidr_range             = local.subnet_cidr
  private_ip_google_access  = true  
}

locals {
  subnet_cidr = "10.0.0.0/16"
}