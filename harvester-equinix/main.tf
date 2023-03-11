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

  ip_address {
    type = "public_ipv4"
    cidr = 31
    }
  ip_address {
    type = "private_ipv4"
    cidr = 30
    }

  depends_on = [equinix_metal_device.harvester1]
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

  ip_address {
    type = "public_ipv4"
    cidr = 31
    }
  ip_address {
    type = "private_ipv4"
    cidr = 30
    }

  depends_on = [equinix_metal_device.harvester1]

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
      write_files:
        - encoding: ""
          content: "tls-san: ${equinix_metal_reserved_ip_block.harvester.address}"
          owner: root
          path: /etc/rancher/rke2/config.yaml.d/30-tls.yaml
          permissions: '0755'
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
    server_url: https://${equinix_metal_reserved_ip_block.harvester.address}:443  
    token: ${var.token}
    os:
      ssh_authorized_keys:
      - ${var.ssh_key}
      password: ${var.password}      # Replace with your password
      dns_nameservers:
      - 1.1.1.1
      - 8.8.8.8
    install:
      mode: join
      networks:
        harvester-mgmt:
          interfaces:
          - name: eth0
          default_route: true
          method: dhcp
      device: /dev/sda # The target disk to install
      #data_disk: /dev/sdb # It is recommended to use a separate disk to store VM data
      iso_url: "https://equinixphilip.s3.amazonaws.com/harvester-v1.1.1-amd64.iso"
      tty: ttyS1,115200n8   # For machines without a VGA console
  CLOUD_CONFIG
}

