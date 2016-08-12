#!/usr/bin/env ruby
#  Brightbox - Storage class loader
#  Copyright (c) 2010, Brightbox Systems
#  Author: Neil Wilson

require 'tmpdir'
require 'uri'
require 'domtrix_core'
require 'domtrix_config'
%w(
  mys_uri_common
  cloudsql_configure_command
  mys_snapshot_command
  mys_restore_command
  pg_restore_command
).each do |file|
  require "domtrix_cloudsql/#{file}"
end
