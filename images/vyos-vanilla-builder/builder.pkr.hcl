packer {
  required_plugins {
    googlecompute = {
      version = ">= 0.0.1"
      source = "github.com/hashicorp/googlecompute"
    }
  }
}



variable "project-id" {
  description = "Google project id where to build the image"
  type        = string
}
variable "zone" {
  description = "GCP Zone to use for vyos-builder setup"
  type        = string
}
variable "source-image" {
  description = "Base image for vyos-builder instance"
  type        = string
  default     = "debian-11-bullseye-v20211105"
}
variable "vyos-version" {
  description = "Vyos version"
  type        = string
  default     = "equuleus"
}
variable "build-by" {
  description = "Builder reference"
  default     = "vyos-module-packer"
}
variable "artifact-bucket" {
  description = "Target build bucket"
}
variable "image-family" {
  description = "Image family"
  default     = "vyos-vanilla"
}
variable "image-name" {
  description = "Target image name"
}
variable "image-description" {
  description = "Target image description"
  default = ""
}
variable "image-region" {
  description = "Target image region"
  default     = "EU"
}


source "googlecompute" "vyos-builder" {
  project_id        = var.project-id
  zone              = var.zone
  source_image      = var.source-image
  ssh_username      = "packer"
  communicator      = "ssh"

  # We don't want to create an image from this worker: we use it only as builder :)
  skip_create_image = true
  image_name        = var.image-name

}

build {
  sources = ["sources.googlecompute.vyos-builder"]

  # Install builder dependencies
  provisioner "shell" {
    script            = "scripts/1_install_deps.sh"
    environment_vars  = ["VYOS_VERSION=${var.vyos-version}"]
  }

  # Upload build script
  provisioner "file" {
    # The previous script will reboot the VM, as Docker installation requires a logout/login.
    # That is why we configure pasue_before/timeout paramenters here.
    source            = "scripts/build_script.sh"
    pause_before      = "30s"
    timeout           = "30s"
    destination       = "/home/packer/build_scripts/build_script.sh"
  }

  # Pull the builder image
  provisioner "shell" {
    script            = "scripts/2_pull_builder_image.sh"
    environment_vars  = [
      "VYOS_VERSION=${var.vyos-version}",
      "BUILD_BY=${var.build-by}"
    ]
  }

  # Build iso
  provisioner "shell" {
    script            = "scripts/3_build.sh"
    environment_vars  = [
      "VYOS_VERSION=${var.vyos-version}",
      "BUILD_BY=${var.build-by}"
    ]
  }

  # Upload to GCS, create image, remove image from GCS
  provisioner "shell" {
    script            = "scripts/4_upload.sh"
    environment_vars = [
      "TARGET_BUCKET=${var.artifact-bucket}",
      "IMAGE_NAME=${var.image-name}",
      "TARGET_IMAGE_REGION=${var.image-region}",
      "TARGET_IMAGE_FAMILY=${var.image-family}",
    ]
  }
}