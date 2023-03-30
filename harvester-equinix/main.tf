terraform {
  required_providers {
    equinix = {
      source = "equinix/equinix"
    #   version = "1.13.0"
    }
  }
}

resource "equinix_metal_project" "project" {
  name = var.project
}

resource "random_password" "harvester_password" {
  length  = 16
  special = false
}


resource "equinix_metal_reserved_ip_block" "harvester" {
  project_id = equinix_metal_project.project.id
  facility   = var.facility
  quantity   = 1
}

resource "equinix_metal_device" "harvester1" {
  hostname         = "Harvester1"
  plan             = var.instance_size
  metro            = var.metro
  operating_system = "custom_ipxe"
  billing_cycle    = "hourly"
  project_id       = equinix_metal_project.project.id
  ipxe_script_url  = "https://raw.githubusercontent.com/brooksphilip/ipxe-examples/main/equinix/ipxe-install"
  always_pxe       = "false"

  user_data = templatefile("${path.module}/cloud_config_init.tpl", { password = random_password.harvester_password.result, token = var.token,  ssh_key = var.ssh_key, tls_san = equinix_metal_reserved_ip_block.harvester.address, vip = equinix_metal_reserved_ip_block.harvester.address, cluster_registration_url = var.cluster_registration_url })

  depends_on = [equinix_metal_device.harvester_dhcp]

}

resource "equinix_metal_ip_attachment" "harvester1" {
  device_id = equinix_metal_device.harvester1.id
  # following expression will result to sth like "147.229.10.152/32"
  cidr_notation = join("/", [cidrhost(equinix_metal_reserved_ip_block.harvester.cidr_notation, 0), "32"])
}

resource "equinix_metal_device_network_type" "harvester1" {
  device_id = equinix_metal_device.harvester1.id
  type      = "hybrid"
}

resource "equinix_metal_port_vlan_attachment" "harvester1" {
  device_id = equinix_metal_device_network_type.harvester1.id
  port_name = "eth1"
  vlan_vnid = equinix_metal_vlan.workload_vlan.vxlan
}


resource "equinix_metal_device" "harvester2" {
  count = var.build_cluster ? 1 : 0
  hostname         = "Harvester2"
  plan             = var.instance_size
  metro            = var.metro
  operating_system = "custom_ipxe"
  billing_cycle    = "hourly"
  project_id       = equinix_metal_project.project.id
  ipxe_script_url  = "https://raw.githubusercontent.com/brooksphilip/ipxe-examples/main/equinix/ipxe-install"
  always_pxe       = "false"

  user_data = templatefile("${path.module}/cloud_config_agent.tpl", { password = random_password.harvester_password.result, token = var.token, vip = equinix_metal_reserved_ip_block.harvester.address, ssh_key = var.ssh_key})

  depends_on = [equinix_metal_device.harvester1, equinix_metal_device.harvester_dhcp]
}

resource "equinix_metal_device_network_type" "harvester2" {
  device_id = equinix_metal_device.harvester2[0].id
  type      = "hybrid"
}

resource "equinix_metal_port_vlan_attachment" "harvester2" {
  device_id = equinix_metal_device_network_type.harvester2.id
  port_name = "eth1"
  vlan_vnid = equinix_metal_vlan.workload_vlan.vxlan
}

resource "equinix_metal_device" "harvester3" {
  count = var.build_cluster ? 1 : 0
  hostname         = "Harvester3"
  plan             = var.instance_size
  metro            = var.metro
  operating_system = "custom_ipxe"
  billing_cycle    = "hourly"
  project_id       = equinix_metal_project.project.id
  ipxe_script_url  = "https://raw.githubusercontent.com/brooksphilip/ipxe-examples/main/equinix/ipxe-install"
  always_pxe       = "false"

  user_data = templatefile("${path.module}/cloud_config_agent.tpl", { password = random_password.harvester_password.result, token = var.token, vip = equinix_metal_reserved_ip_block.harvester.address, ssh_key = var.ssh_key})

  depends_on = [equinix_metal_device.harvester1, equinix_metal_device.harvester_dhcp]

}

resource "equinix_metal_device_network_type" "harvester3" {
  device_id = equinix_metal_device.harvester3[0].id
  type      = "hybrid"
}

resource "equinix_metal_port_vlan_attachment" "harvester3" {
  device_id = equinix_metal_device_network_type.harvester3.id
  port_name = "eth1"
  vlan_vnid = equinix_metal_vlan.workload_vlan.vxlan
}



# locals {
#   cloud_config_init = <<-CLOUD_CONFIG
#     #cloud-config
#     scheme_version: 1
#     token: ${var.token}
#     os:
#       ssh_authorized_keys:
#       - "${var.ssh_key}"
#       password: "${random_password.harvester_password.result}"
#       write_files:
#         - encoding: ""
#           content: "tls-san: ${equinix_metal_reserved_ip_block.harvester.address}"
#           owner: root
#           path: /etc/rancher/rke2/config.yaml.d/30-tls.yaml
#           permissions: '0755'
#       ntp_servers:
#       - "0.suse.pool.ntp.org"
#       - "1.suse.pool.ntp.org"
#     install:
#       mode: "create"
#       device: "/dev/sda"
#       iso_url: "https://equinixphilip.s3.amazonaws.com/harvester-v1.1.1-amd64.iso"
#       tty: "ttyS1,115200n8"
#       vip: "${equinix_metal_reserved_ip_block.harvester.address}"
#       vip_mode: "static"
#   CLOUD_CONFIG
#   cloud_config_agent = <<-CLOUD_CONFIG
#     #cloud-config
#     scheme_version: 1
#     server_url: https://${equinix_metal_reserved_ip_block.harvester.address}:443  
#     token: ${var.token}
#     os:
#       ssh_authorized_keys:
#       - ${var.ssh_key}
#       password: "${random_password.harvester_password.result}"      # Replace with your password
#       dns_nameservers:
#       - 1.1.1.1
#       - 8.8.8.8
#     install:
#       mode: join
#       device: /dev/sda # The target disk to install
#       #data_disk: /dev/sdb # It is recommended to use a separate disk to store VM data
#       iso_url: "https://equinixphilip.s3.amazonaws.com/harvester-v1.1.1-amd64.iso"
#       tty: ttyS1,115200n8   # For machines without a VGA console
#   CLOUD_CONFIG
# }


#     # %{ if cluster_registration_url != "" }
#     # system_settings:
#     #   cluster-registration-url: ${cluster_registration_url}
#     # %{ endif }


# #       # management_interface:
# #       #   interfaces:
# #       #   - name: eth1
# #       #   method: dhcp
# #       #   vlan_id: ${var.vlan_id}


# #       # networks:
# #       #   harvester-mgmt:
# #       #     interfaces:
# #       #     - name: eth1
# #       #     default_route: true
# #       #     method: dhcp

# #       # enp65s0f1