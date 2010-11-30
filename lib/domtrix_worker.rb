#!/usr/bin/env ruby
#  Brightbox - Domtrix Abstract Class loader
#  Copyright (c) 2010, Brightbox Systems
#  Author: Neil Wilson

require 'socket'
require 'stomp'
require 'syslog'
require 'yaml'
require 'array_shuffle'
require 'domtrix_payload'
require 'domtrix_config'
%w(
worker_manager
).each do |file|
  require "domtrix_worker/#{file}"
end
