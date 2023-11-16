#cloud-config
scheme_version: 1
token: ${token}
os:
  ssh_authorized_keys:
  - "${ssh_key}"
  password: "${password}"
  write_files:
    - encoding: ""
      content: "tls-san: ${tls_san}"
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
  vip: "${vip}"
  vip_mode: "static"
%{ if cluster_registration_url != "" }
system_settings:
    cluster-registration-url: ${cluster_registration_url}
%{ endif }