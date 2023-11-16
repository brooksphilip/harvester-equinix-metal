#cloud-config
scheme_version: 1
server_url: https://${vip}:443  
token: ${token}
os:
  ssh_authorized_keys:
  - ${ssh_key}
  password: "${password}"      # Replace with your password
  dns_nameservers:
  - 1.1.1.1
  - 8.8.8.8
install:
  mode: join
  device: /dev/sda # The target disk to install
  #data_disk: /dev/sdb # It is recommended to use a separate disk to store VM data
  iso_url: "https://equinixphilip.s3.amazonaws.com/harvester-v1.1.1-amd64.iso"
  tty: ttyS1,115200n8   # For machines without a VGA console