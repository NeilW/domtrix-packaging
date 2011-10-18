#!/usr/bin/env ruby
#  Brightbox - Domtrix Configuration class loader
#  Copyright (c) 2010, Brightbox Systems
#  Author: Neil Wilson

require 'yaml'
%w(
queue_config
).each do |file|
  autoload(file.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase },"domtrix_config/#{file}")
end
