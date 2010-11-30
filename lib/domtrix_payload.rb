#!/usr/bin/env ruby
#  Brightbox - Domtrix Abstract Class loader
#  Copyright (c) 2010, Brightbox Systems
#  Author: Neil Wilson

require 'time'
require 'yaml'
%w(
report_payload
task_payload
statistics_payload
).each do |file|
  require "domtrix_payload/#{file}"
end
