require 'json'
require 'erb'

class LoadBalancerConfig

  def initialize(json_config, template)
    @config = JSON.parse(json_config)
    @template = template
  end

  def healthcheck
    @config["healthcheck"]
  end

  def healthcheck_request
    (healthcheck && healthcheck["request"]) || "/"
  end

  def healthcheck_port
    (healthcheck && healthcheck["port"])
  end

  def healthcheck_type
    (healthcheck && healthcheck["type"])
  end

  def healthcheck_interval
    (healthcheck && healthcheck["interval"]) || 5000
  end

  def healthcheck_timeout
    (healthcheck && healthcheck["timeout"]) || 5000
  end

  def healthcheck_threshold_up
    (healthcheck && healthcheck["threshold_up"]) || 3
  end

  def healthcheck_threshold_down
    (healthcheck && healthcheck["threshold_down"]) || 3
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
    case @config['policy']
    when 'least_connections'
      'leastconn'
    else
      'roundrobin'
    end
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
