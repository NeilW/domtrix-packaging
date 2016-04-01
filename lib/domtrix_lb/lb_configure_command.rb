#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2014, Brightbox Systems
#    Author: Neil Wilson
#
#  Load Balancer Configure command.

class LbConfigureCommand < DataCommand
  
private

  include RootPrivileges
  include CommandRunner

  def certdir
    "/etc/haproxy/certs"
  end

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
    if @data.kind_of?(Hash)
      @data[:config]
    else
      @data
    end
  end

  def certificate
    (@data.kind_of?(Hash) && @data[:pem]).to_s
  end

  def other_certificates
    (@data.kind_of?(Hash) && @data[:certs]).to_a
  end

  def haproxy_enabled?
    system("service haproxy status")
  end

  def write_haproxy_config
    write_element(
      config,
      "Updating haproxy config",
      "/etc/haproxy/haproxy.cfg"
    )
  end

  def write_haproxy_certificate
    write_element(
      certificate,
      "Updating haproxy default certificate",
      "/etc/haproxy/ssl_cert.pem"
    )
  end

  def write_element(element, message, filename)
    Syslog.debug message
    File.open(filename, "w") do |f|
      f.write element
    end
    Syslog.debug "Updated."
  end

  def write_other_certificates
    FileUtils.mkdir_p certdir
    FileUtils.rm_f Dir[File.join(certdir, '*')]
    other_certificates.each_with_index do |cert, index|
      write_element(
        cert,
	"Updating cert #{index}",
	File.join(certdir, 'cert%02d.pem' % index)
      )
    end
  end

  def enable_haproxy
    Syslog.debug "Disabled haproxy detected. Enabling"
    run('sed -i \'s/^\(ENABLED=\)0$/\11/\' /etc/default/haproxy', "enable haproxy")
    Syslog.debug "Enabled."
  end

  def restart_haproxy
    Syslog.debug "Attempting online reload"
    if run("service haproxy reload >/dev/null 2>&1", "reload haproxy")
      Syslog.debug "Reloaded"
      return
    end
    if run("service haproxy restart >/dev/null 2>&1", "restart haproxy")
      Syslog.debug "Restarted"
    else
      Syslog.debug "Ignoring failure"
    end
  end

  def start_haproxy
    Syslog.debug "Starting haproxy for first time"
    run("service haproxy start >/dev/null 2>&1", "start haproxy")
    Syslog.debug "Started"
  end

  def data_action
    write_haproxy_config if config
    write_haproxy_certificate if certificate
    write_other_certificates if other_certificates
    if haproxy_enabled?
      restart_haproxy
    else
      enable_haproxy
      start_haproxy
    end
    @state="completed"
  end

end
