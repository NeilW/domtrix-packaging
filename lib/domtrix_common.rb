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

  def bridge_pattern
    /#{BRIDGE_PREFIX}[\da-f]{6}/
  end

  def vlan_pattern
    /#{VLAN_PREFIX}(?:\d{1,4}\.){0,2}\d{1,4}/
  end

  def vlan_network_pattern
    /<source(?:\s+mode="bridge")?\s+dev="#{vlan_pattern}"(?:\s+mode="bridge")?/
  end

  def mac_pattern
    /(?:[0-9A-F]{2}:){5}[0-9A-F]{2}/i
  end

  def mac_network_pattern
    /address="(#{mac_pattern})"/
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
    begin
      v6_net = IPAddr.new(zone_prefix)
    rescue ArgumentError
      # Legacy prefix
      v6_net = IPAddr.new(zone_prefix+'::/48')
    end
    mask = ~v6_net.instance_variable_get(:@mask_addr) & IPAddr::IN6MASK
    mac_section = (stripped_mac(mac).hex<<62) & mask
    (v6_net | mac_section).mask(64).to_s.sub(/::$/,'')
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

  def kernel_version
    `uname -r`.strip
  end

  def working_macvlan?
    kernel_version > '3.10.0'
  end

end
