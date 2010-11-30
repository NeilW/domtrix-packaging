#!/usr/bin/env ruby
#  Brightbox - Domtrix Abstract Class loader
#  Copyright (c) 2010, Brightbox Systems
#  Author: Neil Wilson

%w(
queue_config
).each do |file|
  require "domtrix_config/#{file}"
end
