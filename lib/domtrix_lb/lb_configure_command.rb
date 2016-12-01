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

  def cert_dir
    "/etc/haproxy/certs"
  end

  def config_file
    "/etc/haproxy/haproxy.cfg"
  end

  def cert_file
    "/etc/haproxy/ssl_cert.pem"
  end

  def config_list
    [ cert_dir, config_file, cert_file ]
  end

  def old_suffix
    ".old"
  end

  def old_config_list
    config_list.map {|fn| fn+old_suffix }
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
      config_file
    )
  end

  def write_haproxy_certificate
    write_element(
      certificate,
      "Updating haproxy default certificate",
      cert_file
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
    FileUtils.rm_rf cert_dir
    FileUtils.mkdir_p cert_dir
    other_certificates.each_with_index do |cert, index|
      write_element(
        cert,
	"Updating cert #{index}",
	File.join(cert_dir, 'cert%02d.pem' % index)
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

  def check_haproxy_config
    Syslog.debug "Checking haproxy config"
    run("/usr/sbin/haproxy -f #{config_file} -c -q", "check haproxy", "haproxy check failed")
    Syslog.debug "Finished checking haproxy config"
  end

  def remove_old_config
    FileUtils.rm_rf(old_config_list)
  end

  def conditional_move(source_fn, dest_fn)
    File.rename(source_fn, dest_fn)
  rescue Errno::ENOENT
    #Source file missing - ignore
  rescue Errno::ENOTEMPTY
    #destination directory has entries - zap them
    FileUtils.rm_rf(dest_fn)
    retry
  end

  def write_config
    write_haproxy_config if config
    write_haproxy_certificate unless certificate.empty?
    write_other_certificates unless other_certificates.empty?
  end

  def oldify_config
    config_list.each do |fn|
      conditional_move(fn, fn+old_suffix)
    end
  end

  def restore_old_config
    config_list.each do |fn|
      conditional_move(fn+old_suffix, fn)
    end
  end

  def test_config
    oldify_config
    write_config
    check_haproxy_config
    remove_old_config
  rescue StandardError
    Syslog.info("#{self.class.name}: Check failed - restoring previous config")
    restore_old_config
    raise
  end

  def data_action
    test_config
    if haproxy_enabled?
      restart_haproxy
    else
      enable_haproxy
      start_haproxy
    end
    @state="completed"
  end

end
