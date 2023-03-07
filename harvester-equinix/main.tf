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


resource "equinix_metal_reserved_ip_block" "harvester" {
  project_id = equinix_metal_project.project.id
  facility   = var.facility
  quantity   = 4

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

  user_data = local.cloud_config_init
}


resource "equinix_metal_ip_attachment" "harvester1" {
  device_id = equinix_metal_device.harvester1.id
  # following expression will result to sth like "147.229.10.152/32"
  cidr_notation = join("/", [cidrhost(equinix_metal_reserved_ip_block.harvester.cidr_notation, 0), "32"])
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

  user_data = local.cloud_config_agent

  depends_on = [equinix_metal_device.harvester1]
}

resource "equinix_metal_ip_attachment" "harvester2" {
  count = var.build_cluster ? 1 : 0
  device_id = equinix_metal_device.harvester2[0].id
  # following expression will result to sth like "147.229.10.152/32"
  cidr_notation = join("/", [cidrhost(equinix_metal_reserved_ip_block.harvester.cidr_notation, 1), "32"])
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

  user_data = local.cloud_config_agent

  depends_on = [equinix_metal_device.harvester1]

}

resource "equinix_metal_ip_attachment" "harvester3" {
  count = var.build_cluster ? 1 : 0
  device_id = equinix_metal_device.harvester3[0].id
  # following expression will result to sth like "147.229.10.152/32"
  cidr_notation = join("/", [cidrhost(equinix_metal_reserved_ip_block.harvester.cidr_notation, 2), "32"])
}


locals {
  cloud_config_init = <<-CLOUD_CONFIG
    #cloud-config
    scheme_version: 1
    token: ${var.token}
    os:
      ssh_authorized_keys:
      - "${var.ssh_key}"
      password: "${var.password}"
      ntp_servers:
      - "0.suse.pool.ntp.org"
      - "1.suse.pool.ntp.org"
    install:
      mode: "create"
      device: "/dev/sda"
      iso_url: "https://equinixphilip.s3.amazonaws.com/harvester-v1.1.1-amd64.iso"
      tty: "ttyS1,115200n8"
      vip: "${equinix_metal_reserved_ip_block.harvester.address}"
      vip_mode: "static"
  CLOUD_CONFIG
  cloud_config_agent = <<-CLOUD_CONFIG
    #cloud-config
    scheme_version: 1
    server_url: https://"${equinix_metal_device.harvester1.access_public_ipv4}":443
    token: ${var.token}  # replace with the token you set when creating a new cluster
    os:
      ssh_authorized_keys:
      - ${var.ssh_key}
      password: ${var.password}  # replace with a your password
    install:
      mode: join
      networks:
        harvester-mgmt: # The management bond name. This is mandatory.
          interfaces:
          - name: eth0
          default_route: true
          method: dhcp
      device: /dev/sda
      iso_url: "https://equinixphilip.s3.amazonaws.com/harvester-v1.1.1-amd64.iso"
      tty: ttyS1,115200n
  CLOUD_CONFIG
}
