#    Brightbox - Command processor classes
#    Copyright (C) 2010, Brightbox Systems
#    Author: Neil Wilson
#
#  Wrap the Config settings

class QueueConfig
  
  include Singleton

  DEFAULT_CONFDIR = '/etc/domtrix'

  def config_file
    File.join(ENV['CONFDIR'] || DEFAULT_CONFDIR, 'config.yml')
  end

  def load_config
    @config = YAML.load_file(config_file)
    if @config
      @load_message = "Configuration loaded #{@config.keys.inspect}"
    else
      @load_message = "Using blank config: failure loading #{config_file}"
    end
  rescue Errno::ENOENT
    @load_message = "Using blank config: missing config file #{config_file}"
  rescue Errno::EACCES
    @load_message = "Using blank config: no permission to read config file #{config_file}"
  rescue ArgumentError => e
    @load_message = "Error in config file #{config_file}: #{e.message}"
  end

  attr_reader :load_message

  def [](attribute)
    ENV[attribute.to_s.upcase] ||
      config[attribute.to_s.downcase]
  end

  def write(config, mode=0644)
    yaml_out = YAML.dump(config)
    File.open(config_file, File::CREAT|File::TRUNC|File::WRONLY, mode) { |f| f.write yaml_out }
  end

private 

  def config
    @config || load_config
    @config ||= {}
  end

end
