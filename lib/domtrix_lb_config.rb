require 'json'
require 'erb'

class LoadBalancerConfig

  def initialize(json_config, template_dir)
    @config = JSON.parse(json_config)
    @template_dir = template_dir
  end

  def lb_id
    @config["id"]
  end

  def listeners
    @config['listeners'] || []
  end

  def pool
    @config['pool'] || []
  end

  def balance_method
    @config['method'] || "roundrobin"
  end

  def app_name(listener)
    "#{@config['id']}-#{listener['protocol']}-#{listener['in']}"
  end

  def dns_hostname(name)
    @config['dns_hostname']
  end

  def node_fqdn(name)
    "#{name}.gb1.brightbox.com"
  end

  def haproxy_config
    ERB.new(File.read(template), 0, '>').result(binding)
  end

  def template
    File.join(@template_dir, "haproxy.cfg.erb")
  end

end
