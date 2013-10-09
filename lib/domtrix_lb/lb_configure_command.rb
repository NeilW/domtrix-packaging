#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2010, Neil Wilson, Brightbox Systems
#
#  Load Balancer Configure command.

class LbConfigureCommand < DataCommand
  
  include RootPrivileges
  include CommandRunner

private

  def valid_data?
    super || valid_string?
  end

  def valid_string?
    (@data && @data.kind_of?(String) && !@data.empty?)
  end

  def required_elements_present?
    config
  end

  def config
    if @data.kind_of(Hash)
      @data[:config]
    else
      @data
    end
  end

  def certificate
    @data.kind_of?(Hash) && @data[:pem]
  end

  def haproxy_enabled?
    system("grep -q '^ENABLED=1$' /etc/default/haproxy")
  end

  def write_haproxy_config
    Syslog.debug "Updating haproxy config"
    File.open("/etc/haproxy/haproxy.cfg", "w") do |f|
      f.write config
    end
    Syslog.debug "Updated."
  end

  def write_haproxy_certificate
    Syslog.debug "Updating haproxy certificate"
    File.open("/etc/haproxy/ssl_cert.pem", "w") do |f|
      f.write certificate
    end
    Syslog.debug "Updated."
  end

  def enable_haproxy
    Syslog.debug "Disabled haproxy detected. Enabling"
    run('sed -i \'s/^\(ENABLED=\)0$/\11/\' /etc/default/haproxy', "enable haproxy")
    Syslog.debug "Enabled."
  end

  def restart_haproxy
    Syslog.debug "Restarting haproxy"
    run("service haproxy restart >/dev/null 2>&1", "restart haproxy")
    Syslog.debug "Restarted"
  end

  def start_haproxy
    Syslog.debug "Starting haproxy for first time"
    run("service haproxy start >/dev/null 2>&1", "start haproxy")
    Syslog.debug "Started"
  end

  def data_action
    write_haproxy_config if config
    write_haproxy_certificate if certificate
    if haproxy_enabled?
      restart_haproxy
    else
      enable_haproxy
      start_haproxy
    end
    @state="completed"
  end

end
