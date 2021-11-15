# GCE VyOS module
[VyOS][1] is an router open source operating system, based on the old [vyatta][2] virtual router implementation.
VyOS runs on bare-metal devices and on all major cloud providers, including Google Cloud Platform.

## Motivation
At the time of writing, there is no easy-to-go way to get VyOS running on GCP, except the Google Marketplace deploy. 
While the [current version of VyOS][4] available on GCP marketplace is paid (even if it is an open-source project)
it is not updated and does not come with Google Compute agent nor Google Ops Agent installed.

## Features
This module achieves two major objectives:
- Creates a terraform-managed VyOS instance
- Implements transparent VyOS configuration updates via Google Cloud Storage and pub-sub notifications

The VyOS instance is built leveraging packer scripts which build the VyOS image from source, install
the GCE agents ([guest agent][5] and [ops agent][6]) and configure the automatic pub-sub 
configuration-updater scripts.

## Requirements

.TBD. (provider, packer, gcp project with billing)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_artifact_bucket_name"></a> [artifact\_bucket\_name](#input\_artifact\_bucket\_name) | Bucket used as artifact scratchpad to build the VyOs image | `any` | `null` | no |
| <a name="input_build_vyos_image"></a> [build\_vyos\_image](#input\_build\_vyos\_image) | When set to true, the module will build the vyos image with packer and name it as `instance_vyos_image_name`.<br>In case you have built the image manually, set this flag to false and reference the vyos image using the<br>`instance_vyos_image_name` variable." | `any` | n/a | yes |
| <a name="input_configuration_bucket_name"></a> [configuration\_bucket\_name](#input\_configuration\_bucket\_name) | Bucket name where to store VyOs instance configuration file | `any` | `null` | no |
| <a name="input_configuration_bucket_path"></a> [configuration\_bucket\_path](#input\_configuration\_bucket\_path) | GCS object path where to store VyOs instance configuration file | `any` | `null` | no |
| <a name="input_gcp_region"></a> [gcp\_region](#input\_gcp\_region) | Default GCP region where to spawn resources | `any` | n/a | yes |
| <a name="input_instance_name"></a> [instance\_name](#input\_instance\_name) | Name to assign to the VyOs instance | `string` | `"vyos"` | no |
| <a name="input_instance_network_self_link"></a> [instance\_network\_self\_link](#input\_instance\_network\_self\_link) | VPC network self-link where to attach the VyOs instance | `any` | n/a | yes |
| <a name="input_instance_private_ip"></a> [instance\_private\_ip](#input\_instance\_private\_ip) | Private network ip to assign to VyOs instance | `any` | n/a | yes |
| <a name="input_instance_subnet_network_self_link"></a> [instance\_subnet\_network\_self\_link](#input\_instance\_subnet\_network\_self\_link) | Subnet self-link where to attach che VyOs instance | `any` | n/a | yes |
| <a name="input_instance_tags"></a> [instance\_tags](#input\_instance\_tags) | Tags to assign to the vyos instance | `list` | <pre>[<br>  "vyos"<br>]</pre> | no |
| <a name="input_instance_tier"></a> [instance\_tier](#input\_instance\_tier) | Machine tier for the VyOs instance | `string` | `"e2-small"` | no |
| <a name="input_instance_vyos_image_name"></a> [instance\_vyos\_image\_name](#input\_instance\_vyos\_image\_name) | Instance image name | `any` | n/a | yes |
| <a name="input_instance_vyos_image_region"></a> [instance\_vyos\_image\_region](#input\_instance\_vyos\_image\_region) | Instance image region | `string` | `"EU"` | no |
| <a name="input_instance_zone"></a> [instance\_zone](#input\_instance\_zone) | GCP Zone where to spawn the VyOs instance | `any` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Google project id where to spawn the VyOs instance | `any` | n/a | yes |
| <a name="input_vyos_configuration_content"></a> [vyos\_configuration\_content](#input\_vyos\_configuration\_content) | Contents of the VyOs configuration to apply to the target instance | `any` | n/a | yes |
| <a name="input_vyos_vanilla_image_name"></a> [vyos\_vanilla\_image\_name](#input\_vyos\_vanilla\_image\_name) | Name for the vyos vanilla image to build | `string` | `"vyos-vanilla"` | no |



## Licensing notes
This module is provided as is, with absolutely no warranty.

Quoting the [original documentation][3], we read:
```
VyOS is now free as in speech, but not as in beer. 
This means that while VyOS is still an open source project, 
the release ISOs are no longer free and can only be obtained 
via subscription, or by contributing to the community.
``` 


```bash
packer init builder.pkr.hcl
```

```bash
packer build -var "zone=europe-west3-c" -var "project-id=devops-dev-264808" -var "artifact-bucket=gs://devops-dev-264808-vyos-artifacts" builder.pkr.hcl
```

[1]: https://vyos.io/
[2]: https://en.wikipedia.org/wiki/Vyatta
[3]: https://docs.vyos.io/en/equuleus/contributing/build-vyos.html#prerequisites
[4]: https://console.cloud.google.com/marketplace/details/sentrium-sl/vyos?pli=1&__hstc=29142691.81c103d48b29bf69a308c8fc19c4c385.1589665573318.1599490605499.1599492713182.137&__hssc=29142691.11.1599492713182&__hsfp=2286654099&hsCtaTracking=9eef7ede-be44-49bd-aec6-f348ff4ab420%7C881f8bd5-facc-4f16-9640-50339c90751d
[5]: https://github.com/GoogleCloudPlatform/guest-agent
[6]: https://cloud.google.com/monitoring/agent/ops-agent