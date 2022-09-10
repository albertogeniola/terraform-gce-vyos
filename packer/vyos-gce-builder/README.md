# Prerequisites
Create a vyos-vanilla image starting from the artifact built and published as release on this project

# Invoke the builder
packer init builder.pkr.hcl
packer build -var "project-id=geniola-builder" -var "zone=europe-west8-b" -var "vyos-vanilla-source-image=vyos-vanilla" -var "network=packerbuilders" -var "tag=ssh-iap" -var "use-iap=true" builder.pkr.hcl
