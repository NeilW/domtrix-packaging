#!/usr/bin/env ruby
#  Brightbox - Domtrix Async command class loader
#  Copyright (c) 2013, Brightbox Systems
#  Author: Neil Wilson

require 'uri'
require 'syslog'
require 'domtrix_cache'

target=File.basename(__FILE__, '.rb')
Dir.open(File.join(File.dirname(__FILE__),target)) do |d|
  d.each do |f|
    if f =~ /\.rb$/
      file = File.basename f, '.rb'
      autoload(file.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase },File.join(target,file))
    end
  end
end
