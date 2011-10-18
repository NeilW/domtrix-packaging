#!/usr/bin/env ruby
#  Brightbox - Statistics class loader
#  Copyright (c) 2011, Brightbox Systems
#  Author: Neil Wilson

require 'yaml'
module DomtrixStats
  %w(
    triggerable
    domain_info_decoder
    stats_processor
    domain_info
    interface_info
    uptime_info
    inet_info
  ).each do |file|
    autoload(file.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase },"domtrix_stats/#{file}")
  end
end
