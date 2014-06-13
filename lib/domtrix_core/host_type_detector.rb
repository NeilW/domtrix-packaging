#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2012, Brightbox Systems
#    Author: Neil Wilson
#
#  Module to detect and handle the difference between a libvirt and vlan host
#  Encapsulate the workaround to handle the macvlan fault.

module HostTypeDetector

  include DomtrixCommon

  def native_network_host?
    File.exists?(IPTABLES_FILE) && File.open(IPTABLES_FILE) {|f| f.grep(/:libvirt/).empty? }
  end

  def detect_host_interface(bridge_name)
    if native_network_host?
#      NativeMacvlanInterface.new(bridge_name)
      NativeBridgeInterface.new(bridge_name)
    else
      LibvirtBridgeInterface.new(bridge_name)
    end
  end

  def adjust_domain_xml_for_host_type(server_xml)
    return unless vlan_network?(server_xml)
    if native_network_host?
      NativeBridge.adjust_domain_xml(server_xml)
    else
      LibvirtBridge.adjust_domain_xml(server_xml)
    end
  end

  def vlan_network?(server_xml)
    server_xml =~ vlan_network_pattern
  end

private
  
  IPTABLES_FILE='/etc/sysconfig/iptables'

  module NativeBridge
    extend DomtrixCommon
    def self.adjust_domain_xml(server_xml)
      mac_address = server_xml.match(mac_network_pattern) && Regexp.last_match[1]
      server_xml.sub!('direct', 'bridge')
      server_xml.sub!(vlan_network_pattern, "<source bridge='#{bridgename mac_address}'")
    end

  end

  module LibvirtBridge
    extend DomtrixCommon
    def self.adjust_domain_xml(server_xml)
      mac_address = server_xml.match(mac_network_pattern) && Regexp.last_match[1]
      server_xml.sub!('direct', 'network')
      server_xml.sub!(vlan_network_pattern, "<source network='#{bridgename mac_address}'")
      server_xml.sub!('</interface>', '<filterref filter="dummy"/>\0')
      server_xml.sub!('io="native"','')
      server_xml.sub!('ioeventfd="on"','')
    end
  end

end
