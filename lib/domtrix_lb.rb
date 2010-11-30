#!/usr/bin/env ruby
#  Brightbox - Storage class loader
#  Copyright (c) 2010, Brightbox Systems
#  Author: Neil Wilson

require 'domtrix_core'
%w(
  lb_configure_command
).each do |file|
  require "domtrix_lb/#{file}"
end
