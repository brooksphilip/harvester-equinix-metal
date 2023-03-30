#cloud-config
hostname: ${node_name}
users:
  - name: terraform
    passwd: $${random_password.password.result}
resize_rootfs: true
write_files:
- path: /etc/dhcp/dhcpd.conf
  content: ${dhcp_conf_b64}
  encoding: b64
  owner: root:root
  permissions: 0644
- path: /root/configurenetwork.sh
  owner: root:root
  permissions: 0755
  content: |
    #!/bin/bash
    interfaces=( $(cat /sys/class/net/bond0/bonding/slaves) )
    ifdown bond0
    ip link delete bond0
    echo "-$${interfaces[-1]}" >  /sys/class/net/bond0/bonding/slaves
    echo "-$${interfaces[0]}" >  /sys/class/net/bond0/bonding/slaves
    ifdown $${interfaces[-1]}
    ifdown $${interfaces[0]}
    cat << EOF > /etc/network/interfaces
    auto $${interfaces[-1]}
    iface $${interfaces[-1]} inet static
      address ${address}
      netmask ${netmask}
      gateway ${gateway}
    EOF
    cat << EOF > /etc/default/isc-dhcp-server
    INTERFACESv4="$${interfaces[-1]}"
    EOF
    ifup $${interfaces[-1]}
packages:
  - isc-dhcp-server
runcmd:
- /root/configurenetwork.sh
- sytemctl enable isc-dhcp-server
- systemctl start isc-dhcp-server
