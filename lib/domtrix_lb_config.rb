require 'json'
require 'erb'

class LoadBalancerConfig

  def initialize(json_config, template)
    @config = JSON.parse(json_config)
    @template = template
  end

  def lb_id
    @config["id"]
  end

  def listeners
    @config['listeners'] || []
  end

  def nodes
    @config['nodes'] || []
  end

  def balance_method
    @config['policy'] || "roundrobin"
  end

  def app_name(listener)
    "#{@config['id']}-#{listener['protocol']}-#{listener['in']}"
  end

  def dns_hostname(name)
    @config['dns_hostname']
  end

  def haproxy_config
    ERB.new(@template, 0, '>').result(binding)
  end

end
