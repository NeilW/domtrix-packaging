#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2010, Neil Wilson, Brightbox Systems
#
#  Load Balancer Configure command.

class LbConfigureCommand < DataCommand
  
  include RootPrivileges

private

  def valid_data?
    @data &&
    !@data.empty?
  end

  def run(command, error_message)
    system(command)
    unless $?.success?
      if $?.exited?
	raise RuntimeError, "(#{$?.exitstatus}): " + error_message
      else
	raise RuntimeError, "Abnormal exit:" + error_message
      end
    end
  end

  def haproxy_enabled?
    system("grep -q '^ENABLED=1$' /etc/default/haproxy")
  end

  def write_haproxy_config
    Syslog.debug "Updating haproxy config"
    File.open("/etc/haproxy/haproxy.cfg", "w") do |f|
      f.write @data
    end
    Syslog.debug "Updated."
  end

  def enable_haproxy
    Syslog.debug "Disabled haproxy detected. Enabling"
    run('sed -i \'s/^\(ENABLED=\)0$/\11/\' /etc/default/haproxy', "Problem enabling haproxy")
    Syslog.debug "Enabled."
  end

  def restart_haproxy
    Syslog.debug "Restarting haproxy"
    run("service haproxy restart >/dev/null 2>&1", "Failed to restart haproxy")
    Syslog.debug "Restarted"
  end

  def start_haproxy
    Syslog.debug "Starting haproxy for first time"
    run("service haproxy start >/dev/null 2>&1", "Failed to start haproxy")
    Syslog.debug "Started"
  end

  def data_action
    write_haproxy_config
    if haproxy_enabled?
      restart_haproxy
    else
      enable_haproxy
      start_haproxy
    end
    @state="completed"
  end

end
