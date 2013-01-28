#    Brightbox - Command processor classes
#    Copyright (C) 2012, Brightbox Systems
#    Author: Neil Wilson
#
#  Module containing common functions

module DomtrixCommon
  
  VLAN_PREFIX='vl'
  BRIDGE_PREFIX='br'

  def suffix(mac_address)
    mac_address.split(":")[-3..-1].join("")
  end

  def bridgename(mac_address)
    "#{BRIDGE_PREFIX}#{suffix(mac_address)}"
  end

  def bridge_from_ip(ip4addr)
    "#{BRIDGE_PREFIX}%06x" % (ip4addr.to_i & 0xFFFFFF)
  end

  def ip_from_bridge(bridge)
    ipaddr(bridge.sub(/^#{BRIDGE_PREFIX}/,'').hex)
  end

  def vlan_pattern
    /#{VLAN_PREFIX}(?:\d{1,4}\.){0,2}\d{1,4}/
  end

  def mac_pattern
    /(?:[0-9A-F]{2}:){5}[0-9A-F]{2}/i
  end

  def vlan_id(tag_list)
    VLAN_PREFIX + tag_list.join('.')
  end

  def vlan_list_from_id(vlan_name)
    vlan_name[VLAN_PREFIX.length..-1].split('.')
  end

  def ipaddr(value)
    "10.#{(value & 0xFF0000)>>16}.#{(value & 0xFF00)>>8}.#{value & 0xFF}"
  end

  # Returns the IPv6 64 bit network as a string.
  def ipv6_network(zone_prefix, mac)
    server_network = '%04x' % (stripped_mac(mac).hex>>2 & 0xFFFF)
    "#{zone_prefix}:#{server_network}"
  end

  # Mac without the ':'
  def stripped_mac(mac)
    mac.gsub(':','')
  end

  # EUI64 as a number
  def eui64_number(mac)
    temp = stripped_mac(mac)
    eui64 = (temp[0..5]+'fffe'+temp[-6..-1]).hex ^ (1 << 57)
  end

end
