#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2012, Brightbox Systems
#    Author: Neil Wilson
#
#  Module to detect and handle the difference between a libvirt and vlan host

module HostTypeDetector

  include DomtrixCommon

  def native_network_host?
    File.exists?(IPTABLES_FILE) && File.open(IPTABLES_FILE) {|f| f.grep(/:libvirt/).empty? }
  end

  def detect_host_interface(bridge_name)
    if native_network_host?
      HostInterface.new(bridge_name)
    else
      BridgeInterface.new(bridge_name)
    end
  end

  def adjust_domain_xml_for_host_type(server_xml)
    return if native_network_host? || ! vlan_network?(server_xml)
    mac_address = server_xml.match(/address="([0-9a-fA-F:]{17})"/) && Regexp.last_match[1]
    server_xml.sub!('direct', 'network')
    server_xml.sub!(vlan_network_pattern, "<source network='#{bridgename mac_address}'")
    server_xml.sub!('</interface>', '<filterref filter="dummy"/>\0')
  end

  def vlan_network?(server_xml)
    server_xml =~ vlan_network_pattern
  end

private
  
  IPTABLES_FILE='/etc/sysconfig/iptables'

  def vlan_network_pattern
    /<source(?:\s+mode="bridge")?\s+dev="#{vlan_pattern}"(?:\s+mode="bridge")?/
  end
end
