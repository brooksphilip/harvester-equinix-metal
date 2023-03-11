terraform {
  required_providers {
    equinix = {
      source = "equinix/equinix"
    #   version = "1.13.0"
    }
  }
}

data "equinix_metal_project" "project" {
  name = var.project
}


resource "equinix_metal_reserved_ip_block" "harvester" {
  project_id = data.equinix_metal_gateway.harvester
  facility   = var.facility
  quantity   = 1
}

############ Harvester Host 1 ##################
resource "equinix_metal_device" "harvester1" {
  hostname         = "Harvester1"
  plan             = var.instance_size
  metro            = var.metro
  operating_system = "custom_ipxe"
  billing_cycle    = "hourly"
  project_id       = data.equinix_metal_gateway.harvester
  ipxe_script_url  = "https://raw.githubusercontent.com/brooksphilip/ipxe-examples/main/equinix/ipxe-install"
  always_pxe       = "false"

  user_data = local.cloud_config_init

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

resource "equinix_metal_port_vlan_attachment" "harvester" {
  device_id = equinix_metal_device_network_type.harvester1.id
  port_name = "eth1"
  vlan_vnid = data.equinix_metal_gateway.harvester
}

############ Harvester Host 2 ##################
resource "equinix_metal_device" "harvester2" {
  count = var.build_cluster ? 1 : 0
  hostname         = "Harvester2"
  plan             = var.instance_size
  metro            = var.metro
  operating_system = "custom_ipxe"
  billing_cycle    = "hourly"
  project_id       = data.equinix_metal_gateway.harvester
  ipxe_script_url  = "https://raw.githubusercontent.com/brooksphilip/ipxe-examples/main/equinix/ipxe-install"
  always_pxe       = "false"

  user_data = local.cloud_config_agent1

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

resource "equinix_metal_device_network_type" "harvester2" {
  device_id = equinix_metal_device.harvester1.id
  type      = "hybrid"
}

resource "equinix_metal_port_vlan_attachment" "harvester2" {
  device_id = equinix_metal_device_network_type.harvester2.id
  port_name = "eth1"
  vlan_vnid = data.equinix_metal_gateway.harvester

   depends_on = [equinix_metal_device.harvester1, equinix_metal_device_network_type.harvester2]
}

############ Harvester Host 3 ##################
resource "equinix_metal_device" "harvester3" {
  count = var.build_cluster ? 1 : 0
  hostname         = "Harvester3"
  plan             = var.instance_size
  metro            = var.metro
  operating_system = "custom_ipxe"
  billing_cycle    = "hourly"
  project_id       = data.equinix_metal_gateway.harvester
  ipxe_script_url  = "https://raw.githubusercontent.com/brooksphilip/ipxe-examples/main/equinix/ipxe-install"
  always_pxe       = "false"

  user_data = local.cloud_config_agent1

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

resource "equinix_metal_device_network_type" "harvester3" {
  device_id = equinix_metal_device.harvester1.id
  type      = "hybrid"
}

resource "equinix_metal_port_vlan_attachment" "harvester3" {
  device_id = equinix_metal_device_network_type.harvester3.id
  port_name = "eth1"
  vlan_vnid = data.equinix_metal_gateway.harvester

  depends_on = [equinix_metal_device.harvester1, equinix_metal_device_network_type.harvester3]
}

