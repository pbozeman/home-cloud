# manually set/verified:
#   create terraform user
#   terraform import unifi_network.lan name=Default
#   site wide led off
#   wireless meshing off
#   ipv6 off
#   multicast dns on
#   kids network content filtering on


terraform {
  required_providers {
    unifi = {
      source  = "paultyng/unifi"
      version = "0.41.0"
    }
  }
}

locals {
  vlans = {
    "Trusted" = { vlan_id = var.trusted_vlan, dhcp_dns = ["1.1.1.2", "1.0.0.2"] },
    "Kids"    = { vlan_id = var.kids_vlan, dhcp_dns = ["1.1.1.3", "1.0.0.3"] },
    "IoT"     = { vlan_id = var.iot_vlan, dhcp_dns = ["1.1.1.2", "1.0.0.2"] },
    "Guest"   = { vlan_id = var.guest_vlan, dhcp_dns = ["1.1.1.2", "1.0.0.2"] },
  }

  wlans = {
    (var.trusted_ssid) = { network = "Trusted", passphrase = var.trusted_passphrase },
    (var.kids_ssid)    = { network = "Kids", passphrase = var.kids_passphrase },
    (var.guest_ssid)   = { network = "Guest", passphrase = var.guest_passphrase },
    (var.iot_ssid)     = { network = "IoT", passphrase = var.iot_passphrase },
  }

  # the 1.1.1.1 is a hack to provide at least 1 element in the array. Unifi
  # throws an error when the members array of a firewall group drops
  # from >= 1 down to 0.  (It is fine with 0 elements on the initial create,
  # but not on a subsquent modify down to 0.)  The 1.1.1.1 should be a safe
  # enough choice here as it won't exist on our network.
  iot_with_internet_access = concat(["1.1.1.1"], [
    for client_id, client in var.clients : client.ip if client.allow_internet
  ])

  # see comment above re 1.1.1.1
  iot_with_k3s_ingress_access = concat(["1.1.1.1"], [
    for client_id, client in var.clients : client.ip if client.allow_k3s_ingress
  ])
}

data "unifi_ap_group" "default" {
}

data "unifi_user_group" "default" {
}

resource "unifi_user" "clients" {
  for_each = var.clients

  name     = each.value.name
  mac      = each.value.mac
  fixed_ip = each.value.ip
}

# Note: the default network already exist and so it must be imported with
#   terraform import module.unifi.unifi_network.lan name=Default
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
  domain_name   = var.domain_name
  multicast_dns = true
  dhcp_dns      = ["1.1.1.2", "1.0.0.2"]

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

resource "unifi_network" "network" {
  for_each = local.vlans
  name     = each.key

  purpose       = "corporate"
  vlan_id       = each.value.vlan_id
  subnet        = "192.168.${each.value.vlan_id}.0/24"
  dhcp_enabled  = true
  dhcp_start    = "192.168.${each.value.vlan_id}.100"
  dhcp_stop     = "192.168.${each.value.vlan_id}.254"
  domain_name   = var.domain_name
  multicast_dns = true
  dhcp_dns      = each.value.dhcp_dns

  dhcp_v6_start     = "::2"
  dhcp_v6_stop      = "::7d1"
  ipv6_pd_interface = "wan"
  ipv6_pd_start     = "::2"
  ipv6_pd_stop      = "::7d1"
  ipv6_ra_priority  = "high"
  wan_type_v6       = "disabled"
}

resource "unifi_wlan" "wlan" {
  for_each = local.wlans
  name     = each.key

  passphrase = each.value.passphrase
  network_id = unifi_network.network[each.value.network].id
  security   = "wpapsk"

  # enable WPA2/WPA3 support
  wpa3_support    = true
  wpa3_transition = true
  pmf_mode        = "optional"

  ap_group_ids  = [data.unifi_ap_group.default.id]
  user_group_id = data.unifi_user_group.default.id
}

#
# Device/Port overrides
#

resource "unifi_port_profile" "vlan" {
  for_each              = local.vlans
  name                  = each.key
  forward               = "customize"
  native_networkconf_id = unifi_network.network[each.key].id
}

resource "unifi_device" "switches" {
  for_each = var.switches

  name = each.value.name
  mac  = each.value.mac

  dynamic "port_override" {
    for_each = each.value.port_overrides
    content {
      number          = port_override.value.number
      name            = port_override.value.name
      port_profile_id = unifi_port_profile.vlan[port_override.value.port_profile].id
    }
  }

  # TODO: eventually change this to true
  forget_on_destroy = false
}

# used https://fictionbecomesfact.com/unifi-setup-iot-vlan as a reference
# for the basic rules and structure, and then expanded

#
# Firewall groups
#
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

resource "unifi_firewall_group" "https_port" {
  name    = "https_port"
  type    = "port-group"
  members = ["443"]
}

resource "unifi_firewall_group" "k3s_ingress" {
  name    = "k3s_ingress"
  type    = "address-group"
  members = [var.k3s_ingress_ip]
}

resource "unifi_firewall_group" "external_dns" {
  name    = "external_dns"
  type    = "address-group"
  members = ["1.1.1.2", "1.0.0.2"]
}

resource "unifi_firewall_group" "iot_internet_allowed" {
  name    = "iot_internet_allowed"
  type    = "address-group"
  members = local.iot_with_internet_access
}

resource "unifi_firewall_group" "iot_k3s_ingress_allowed" {
  name    = "iot_k3s_ingress_allowed"
  type    = "address-group"
  members = local.iot_with_k3s_ingress_access
}

#
# LAN rules.
#
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
  dst_firewall_group_ids = [
    unifi_firewall_group.local_dns.id,
    unifi_firewall_group.dns_port.id
  ]
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

resource "unifi_firewall_rule" "allow_trusted_to_lan" {
  action      = "accept"
  name        = "allow Trusted to LAN"
  rule_index  = 2003
  ruleset     = "LAN_IN"
  protocol    = "all"
  src_address = unifi_network.network["Trusted"].subnet
  dst_address = unifi_network.lan.subnet
}

resource "unifi_firewall_rule" "allow_trusted_to_iot" {
  action      = "accept"
  name        = "allow Trusted to IoT"
  rule_index  = 2004
  ruleset     = "LAN_IN"
  protocol    = "all"
  src_address = unifi_network.network["Trusted"].subnet
  dst_address = unifi_network.network["IoT"].subnet
}

resource "unifi_firewall_rule" "allow_specfic_iot_to_k3s_ingress" {
  action                 = "accept"
  name                   = "allow specific IoT to K3s ingress"
  rule_index             = 2005
  ruleset                = "LAN_IN"
  protocol               = "all"
  src_firewall_group_ids = [unifi_firewall_group.iot_k3s_ingress_allowed.id]
  dst_firewall_group_ids = [
    unifi_firewall_group.k3s_ingress.id,
    unifi_firewall_group.https_port.id
  ]
}

resource "unifi_firewall_rule" "drop_traffic_between_vlans" {
  action                 = "drop"
  name                   = "drop traffic between VLANs"
  rule_index             = 2999
  ruleset                = "LAN_IN"
  protocol               = "all"
  src_firewall_group_ids = [unifi_firewall_group.rfc1918.id]
  dst_firewall_group_ids = [unifi_firewall_group.rfc1918.id]
}

#
# WAN rules. (note: index is scoped to the ruleset, so we start over at 2000)
#

# TODO: setup internal dns so that this isn't necessary
resource "unifi_firewall_rule" "allow_specfic_iot_to_external_dns" {
  action                 = "accept"
  name                   = "allow specific IoT to Internet"
  rule_index             = 2000
  ruleset                = "WAN_OUT"
  protocol               = "all"
  src_firewall_group_ids = [unifi_firewall_group.iot_k3s_ingress_allowed.id]
  dst_firewall_group_ids = [unifi_firewall_group.external_dns.id]
}

resource "unifi_firewall_rule" "allow_specfic_iot_to_internet" {
  action                 = "accept"
  name                   = "allow specific IoT to Internet"
  rule_index             = 2001
  ruleset                = "WAN_OUT"
  protocol               = "all"
  src_firewall_group_ids = [unifi_firewall_group.iot_internet_allowed.id]

  depends_on = [unifi_firewall_group.iot_internet_allowed]
}

resource "unifi_firewall_rule" "drop_iot_to_internet" {
  action      = "drop"
  name        = "drop traffic to Internet"
  rule_index  = 2999
  ruleset     = "WAN_OUT"
  protocol    = "all"
  src_address = unifi_network.network["IoT"].subnet
}
