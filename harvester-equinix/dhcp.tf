



resource "equinix_metal_vlan" "workload_vlan" {
  description = "harvester-workload-vlan"
  metro    = var.metro
  project_id  = equinix_metal_project.project.id
  vxlan = var.vlan_id
}

resource "equinix_metal_reserved_ip_block" "ip_block" {
  count = var.public_ip_blocks
  project_id = equinix_metal_project.project.id
  type       = "public_ipv4"
  metro      = var.metro
  quantity   = var.public_ip_block_size
  tags = [ "harvester-workload-${count.index+1}"]
}

resource "equinix_metal_gateway" "vlan_gateway" {
  count = var.public_ip_blocks
  project_id               = equinix_metal_project.project.id
  vlan_id                  = equinix_metal_vlan.workload_vlan.id
  ip_reservation_id = equinix_metal_reserved_ip_block.ip_block[count.index].id
}

resource "random_password" "password" {
  length  = 16
  special = false
}

// local variable to generate dhcpd.conf template from the elastic ip ranges
locals  {
    dhcp_conf = <<EOF
default-lease-time 600;
max-lease-time 3600;

%{ for block in equinix_metal_reserved_ip_block.ip_block }
subnet ${block.network} netmask ${block.netmask} {
  range ${cidrhost(block.cidr_notation, 3 )} ${cidrhost(block.cidr_notation, block.quantity -1 )};
  option routers ${block.gateway};
  option domain-name-servers ${var.dns_server};
}
%{ endfor }
EOF    

}

resource "equinix_metal_device" "harvester_dhcp" {
    hostname = "harvester-dhcp"
    plan = "c3.small.x86"
    metro = var.metro
    operating_system = "ubuntu_20_04"
    billing_cycle = "hourly"
    project_id = equinix_metal_project.project.id
    user_data = templatefile("${path.module}/cloud-init.tpl", { dhcp_conf_b64 = base64encode(local.dhcp_conf), node_name = "harvester-dhcp", address = cidrhost(equinix_metal_reserved_ip_block.ip_block.0.cidr_notation, 2 ), gateway = equinix_metal_reserved_ip_block.ip_block.0.gateway, netmask = equinix_metal_reserved_ip_block.ip_block.0.netmask, vlanid = var.vlan_id})

    depends_on = [equinix_metal_gateway.vlan_gateway]
}

resource "equinix_metal_device_network_type" "harvester_dhcp" {
  device_id = equinix_metal_device.harvester_dhcp.id
  type      = "layer2-individual"
}

resource "equinix_metal_port_vlan_attachment" "harvester_dhcp" {
  device_id = equinix_metal_device_network_type.harvester_dhcp.id
  port_name = "eth1"
  vlan_vnid = equinix_metal_vlan.workload_vlan.vxlan
}