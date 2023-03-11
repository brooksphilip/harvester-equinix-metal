
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
  cloud_config_agent1 = <<-CLOUD_CONFIG
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
  # cloud_config_agent2 = <<-CLOUD_CONFIG
  #   #cloud-config
  #   scheme_version: 1
  #   server_url: https://${equinix_metal_reserved_ip_block.harvester.address}:443  
  #   token: ${var.token}
  #   os:
  #     write_files:
  #       - encoding ""
  #         content: |
  #           auto eth1
  #           iface eth1 inet static
  #             address ${equinix_metal_device.harvester2.access_private_ipv4}
  #             netmask 255.255.255.248
  #need to add other shit 
  #     ssh_authorized_keys:
  #     - ${var.ssh_key}
  #     password: ${var.password}      # Replace with your password
  #     dns_nameservers:
  #     - 1.1.1.1
  #     - 8.8.8.8
  #   install:
  #     mode: join
  #     networks:
  #       harvester-mgmt:
  #         interfaces:
  #         - name: eth0
  #         default_route: true
  #         method: dhcp
  #     device: /dev/sda # The target disk to install
  #     #data_disk: /dev/sdb # It is recommended to use a separate disk to store VM data
  #     iso_url: "https://equinixphilip.s3.amazonaws.com/harvester-v1.1.1-amd64.iso"
  #     tty: ttyS1,115200n8   # For machines without a VGA console
  # CLOUD_CONFIG
}
