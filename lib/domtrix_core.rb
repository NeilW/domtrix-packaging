#!/usr/bin/env ruby
#  Brightbox - Domtrix Abstract Class loader
#  Copyright (c) 2010, Brightbox Systems
#  Author: Neil Wilson

%w(
normal_privileges
root_privileges
unknown_command
data_command
abort_command
keepalive
).each do |file|
  require "domtrix_core/#{file}"
end
