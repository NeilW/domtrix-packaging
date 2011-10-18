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
).each do |file|
  autoload(file.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase },"domtrix_core/#{file}")
end
