#!/usr/bin/env ruby
#  Brightbox - Domtrix Main worker loader
#  Copyright (c) 2010, Brightbox Systems
#  Author: Neil Wilson

require 'socket'
require 'stomp'
require 'syslog'
require 'array_shuffle'
require 'domtrix_payload'
require 'domtrix_stats'
require 'domtrix_config'
require 'monitor'
%w(
worker_manager
).each do |file|
  autoload(file.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase },"domtrix_worker/#{file}")
end
