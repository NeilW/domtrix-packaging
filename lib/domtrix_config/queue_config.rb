#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2010, Brightbox Systems
#    Author: Neil Wilson
#
#  Wrap the Config settings

class QueueConfig

  DEFAULT_CONFDIR = '/etc'

  def config_file
    File.join(CONFDIR || DEFAULT_CONFDIR, 'domtrix_config.yml')
  end

  def self.load_config
    @@config = {}
    @@config = YAML.load_file(config_file)
    "Configuration loaded #{@@config.keys.inspect}"
  rescue Errno::ENOENT
    "Using blank config: missing config file #{config_file}"
  rescue Errno::EACCES
    "Using blank config: no permission to read config file #{config_file}"
  rescue ArgumentError => e
    "Error in config file #{config_file}: #{e.message}"
  end

  def self.read(attribute)
    ENV[attribute.upcase] || @@config[attribute.downcase].to_s
  end

end
