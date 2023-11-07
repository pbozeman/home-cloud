# manually set/verrified:
#   site wide led off
#   wireless meshing off
#   ipv6 off
#   multicast dns on

terraform {
  required_providers {
    unifi = {
      source  = "paultyng/unifi"
      version = "0.41.0"
    }
  }
}

provider "unifi" {
  username = var.unifi_username
  password = var.unifi_password
  api_url  = var.unifi_api_url

  # FIXME: install certs
  allow_insecure = true
}

data "unifi_ap_group" "default" {
}

data "unifi_user_group" "default" {
}

resource "unifi_network" "lan" {
  # Leave the name as Default.
  #
  # Its a pain to programatically rename the default network since it would
  # require importing with the old name, editing the file to change the name,
  # and then re-applying.  The resulting file couldn't be used on a fresh
  # install.
  name = "Default"

  purpose       = "corporate"
  subnet        = "192.168.10.0/24"
  dhcp_enabled  = true
  dhcp_start    = "192.168.10.100"
  dhcp_stop     = "192.168.10.254"
  domain_name   = "localdomain"
  multicast_dns = true

  # I'm not using ipv6, but unifi keeps inserting these back into the config
  # for the default network. Add them explicitly so that the terraform diff
  # is clean.
  dhcp_v6_start     = "::2"
  dhcp_v6_stop      = "::7d1"
  ipv6_pd_interface = "wan"
  ipv6_pd_start     = "::2"
  ipv6_pd_stop      = "::7d1"
  ipv6_ra_priority  = "high"
  wan_type_v6       = "disabled"
}

resource "unifi_network" "clients" {
  name          = "Clients"
  purpose       = "corporate"
  vlan_id       = 20
  subnet        = "192.168.20.0/24"
  dhcp_enabled  = true
  dhcp_start    = "192.168.20.100"
  dhcp_stop     = "192.168.20.254"
  domain_name   = "localdomain"
  multicast_dns = true
}

resource "unifi_network" "kids" {
  name          = "Kids"
  purpose       = "corporate"
  vlan_id       = 30
  subnet        = "192.168.30.0/24"
  dhcp_enabled  = true
  dhcp_start    = "192.168.30.100"
  dhcp_stop     = "192.168.30.254"
  domain_name   = "localdomain"
  multicast_dns = true
}

resource "unifi_network" "iot" {
  name          = "IoT"
  purpose       = "corporate"
  vlan_id       = 40
  subnet        = "192.168.40.0/24"
  dhcp_enabled  = true
  dhcp_start    = "192.168.40.100"
  dhcp_stop     = "192.168.40.254"
  domain_name   = "localdomain"
  multicast_dns = true
}

resource "unifi_network" "guest" {
  name          = "Guest"
  purpose       = "corporate"
  vlan_id       = 50
  subnet        = "192.168.50.0/24"
  dhcp_enabled  = true
  dhcp_start    = "192.168.50.100"
  dhcp_stop     = "192.168.50.254"
  domain_name   = "localdomain"
  multicast_dns = true
}

resource "unifi_wlan" "clients" {
  name       = var.clients_ssid
  passphrase = var.clients_passphrase
  network_id = unifi_network.clients.id
  security   = "wpapsk"

  # enable WPA2/WPA3 support
  wpa3_support    = true
  wpa3_transition = true
  pmf_mode        = "optional"

  ap_group_ids  = [data.unifi_ap_group.default.id]
  user_group_id = data.unifi_user_group.default.id
}

resource "unifi_wlan" "guest" {
  name       = var.guest_ssid
  passphrase = var.guest_passphrase
  network_id = unifi_network.guest.id
  security   = "wpapsk"

  # enable WPA2/WPA3 support
  wpa3_support    = true
  wpa3_transition = true
  pmf_mode        = "optional"

  ap_group_ids  = [data.unifi_ap_group.default.id]
  user_group_id = data.unifi_user_group.default.id
}

resource "unifi_wlan" "iot" {
  name       = var.iot_ssid
  passphrase = var.iot_passphrase
  network_id = unifi_network.iot.id
  security   = "wpapsk"

  # enable WPA2/WPA3 support
  wpa3_support    = true
  wpa3_transition = true
  pmf_mode        = "optional"

  ap_group_ids  = [data.unifi_ap_group.default.id]
  user_group_id = data.unifi_user_group.default.id
}

resource "unifi_wlan" "kids" {
  name       = var.kids_ssid
  passphrase = var.kids_passphrase
  network_id = unifi_network.kids.id
  security   = "wpapsk"

  # enable WPA2/WPA3 support
  wpa3_support    = true
  wpa3_transition = true
  pmf_mode        = "optional"

  ap_group_ids  = [data.unifi_ap_group.default.id]
  user_group_id = data.unifi_user_group.default.id
}

# terraformed rules from
# https://fictionbecomesfact.com/unifi-setup-iot-vlan

resource "unifi_firewall_group" "rfc1918" {
  name    = "rfc1918"
  type    = "address-group"
  members = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

resource "unifi_firewall_group" "local_dns" {
  name    = "local_dns"
  type    = "address-group"
  members = [var.local_dns_ip]
}

resource "unifi_firewall_group" "dns_port" {
  name    = "dns_port"
  type    = "port-group"
  members = ["83"]
}

resource "unifi_firewall_rule" "allow_established" {
  action            = "accept"
  name              = "allow established/related sessions"
  rule_index        = 2000
  ruleset           = "LAN_IN"
  state_established = true
  state_related     = true
}

resource "unifi_firewall_rule" "allow_vlan_dns" {
  action                 = "accept"
  name                   = "allow DNS from VLANs"
  rule_index             = 2001
  ruleset                = "LAN_IN"
  protocol               = "all"
  src_firewall_group_ids = [unifi_firewall_group.rfc1918.id]
  dst_firewall_group_ids = [unifi_firewall_group.local_dns.id, unifi_firewall_group.dns_port.id]
}

resource "unifi_firewall_rule" "allow_lan_to_vlans" {
  action                 = "accept"
  name                   = "allow LAN to all VLANs"
  rule_index             = 2002
  ruleset                = "LAN_IN"
  protocol               = "all"
  src_address            = unifi_network.lan.subnet
  dst_firewall_group_ids = [unifi_firewall_group.rfc1918.id]
}

resource "unifi_firewall_rule" "allow_clients_to_lan" {
  action      = "accept"
  name        = "allow Clients to LAN"
  rule_index  = 2003
  ruleset     = "LAN_IN"
  protocol    = "all"
  src_address = unifi_network.clients.subnet
  dst_address = unifi_network.lan.subnet
}

resource "unifi_firewall_rule" "allow_clients_to_iot" {
  action      = "accept"
  name        = "allow Clients to IoT"
  rule_index  = 2004
  ruleset     = "LAN_IN"
  protocol    = "all"
  src_address = unifi_network.clients.subnet
  dst_address = unifi_network.iot.subnet
}

resource "unifi_firewall_rule" "drop_traffic_between_vlans" {
  action                 = "drop"
  name                   = "drop traffic between VLANs"
  rule_index             = 2005
  ruleset                = "LAN_IN"
  protocol               = "all"
  src_firewall_group_ids = [unifi_firewall_group.rfc1918.id]
  dst_firewall_group_ids = [unifi_firewall_group.rfc1918.id]
}
