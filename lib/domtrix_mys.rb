#!/usr/bin/env ruby
#  Brightbox - Storage class loader
#  Copyright (c) 2010, Brightbox Systems
#  Author: Neil Wilson

require 'tmpdir'
require 'uri'
require 'domtrix_core'
require 'domtrix_config'
%w(
  mys_configure_command
  mys_snapshot_command
).each do |file|
  require "domtrix_mys/#{file}"
end
