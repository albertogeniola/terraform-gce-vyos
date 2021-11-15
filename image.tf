# VyOs VANILLA BUILDER
resource "null_resource" "vyos_vanilla" {
  count  = var.build_vyos_image ? 1 : 0
  provisioner "local-exec" {
    command = "packer init builder.pkr.hcl && packer build -force -var project-id=${var.project_id} -var zone=${var.instance_zone} -var artifact-bucket=${google_storage_bucket.artifact_bucket.name} -var image-name=${var.vyos_vanilla_image_name} builder.pkr.hcl"
    working_dir = "${path.module}/images/vyos-vanilla-builder"
  }

  triggers = {
    project_id = var.project_id
    vyos_vanilla_image_name = var.vyos_vanilla_image_name
  }

  depends_on = [google_storage_bucket.artifact_bucket]
}

# VyOs GCE BUILDER
resource "null_resource" "vyos_gce" {
  count  = var.build_vyos_image ? 1 : 0
  provisioner "local-exec" {
    command = "packer init builder.pkr.hcl && packer build -force -var project-id=${var.project_id} -var zone=${var.instance_zone} -var vyos-vanilla-source-image=${var.vyos_vanilla_image_name} -var image-region=${var.instance_vyos_image_region} -var image-name=${var.instance_vyos_image_name} builder.pkr.hcl"
    working_dir = "${path.module}/images/vyos-gce-builder"
  }

  triggers = {
    project_id = var.project_id
    vyos_vanilla_image_name = var.vyos_vanilla_image_name
    instance_vyos_image_region = var.instance_vyos_image_region
    instance_vyos_image_name = var.instance_vyos_image_name
  }

  depends_on = [null_resource.vyos_vanilla]
}