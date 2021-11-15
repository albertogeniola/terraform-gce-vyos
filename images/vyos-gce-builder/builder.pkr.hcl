packer {
  required_plugins {
    googlecompute = {
      version = ">= 0.0.1"
      source = "github.com/hashicorp/googlecompute"
    }
  }
}
############################################################
# VARIABLES
############################################################
variable "project-id" {
  description = "Google project id where to build the image"
  type        = string
}
variable "zone" {
  description = "GCP Zone to use for vyos-builder setup"
  type        = string
}
variable "vyos-vanilla-source-image" {
  description = "Base vyos vanilla image to customize"
  type        = string
}
variable "image-family" {
  description = "Image family"
  default     = "vyos"
}
variable "image-name" {
  description = "Target image name"
  default     = "vyos"
}
variable "image-description" {
  description = "Target image description"
  default     = ""
}
variable "image-region" {
  description = "Target image region"
  default     = "EU"
}
variable "debian-version-name" {
  description = "Debian base version"
  default     = "bullseye"
}
############################################################
# Builder configuration
############################################################
source "googlecompute" "vyos-builder" {
  project_id        = var.project-id
  zone              = var.zone
  source_image      = var.vyos-vanilla-source-image
  communicator      = "ssh"

  ssh_username      = "vyos"
  ssh_password      = "vyos"
  use_os_login      = false

  image_name        = var.image-name
}
############################################################
# Builder script
############################################################
build {
  sources = ["sources.googlecompute.vyos-builder"]

//  provisioner "breakpoint" {
//    disable = false
//    note    = "this is a breakpoint"
//  }

  # Upload ops agent logging conf file
  provisioner "file" {
    source            = "resources/etc/google-cloud-ops-agent/config.yaml"
    destination       = "/home/vyos/config.yaml"
  }
  # Install os-agent and reboot
  provisioner "shell" {
    script            = "scripts/install.sh"
    environment_vars  = ["DEBIAN_VERSION_NAME=${var.debian-version-name}"]
  }

  # Upload login_helper
  provisioner "file" {
    source            = "resources/opt/login_helper"
    pause_before      = "60s"
    timeout           = "30s"
    destination       = "/opt"
  }
  provisioner "file" {
    source            = "resources/etc/systemd/system/login_helper.service"
    destination       = "/home/vyos/login_helper.service"
  }

  # Upload conf_reloader
  provisioner "file" {
    source            = "resources/etc/systemd/system/conf_reloader.service"
    destination       = "/home/vyos/conf_reloader.service"
  }
  provisioner "file" {
    source            = "resources/opt/conf_reloader"
    destination       = "/opt"
  }
  # Upload motd
  provisioner "file" {
    source            = "resources/etc/motd"
    destination       = "/home/vyos/motd"
  }
  # Configure
  provisioner "shell" {
    script            = "scripts/configure.sh"
    environment_vars  = []
  }
  # Vyos Basic configuration
  provisioner "shell" {
    script            = "scripts/vyos_basic_config.sh"
    environment_vars  = []
  }
}