#!/usr/bin/env ruby
#  Brightbox - Domtrix Abstract Class loader
#  Copyright (c) 2010, Brightbox Systems
#  Author: Neil Wilson

require 'domtrix_common'
%w(
normal_privileges
root_privileges
unknown_command
data_command
abort_command
command_runner
init_detector
).each do |file|
  autoload(file.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase },"domtrix_core/#{file}")
end
