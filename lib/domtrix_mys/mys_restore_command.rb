#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2013, Neil Wilson, Brightbox Systems
#
#  Mysql Restore Command

class MysRestoreCommand < DataCommand

private
  
  include RootPrivileges
  include DomtrixConfig
  include CommandRunner
  include MysUriCommon

  def mys_restore_command
    "nice curl --silent --show-error --fail #{curl_token_option} #{target_uri_name} | tar --extract #{compression_tag} --directory #{data_area} ."
  end

  def service_running_command
    "status mysql 2>/dev/null | grep -q running"
  end

  def stop_service_command
    "stop --quiet mysql"
  end

  def zero_data_area
    Syslog.info("#{self.class.name}: Zeroing MySQL data area - #{data_area}")
    FileUtils.rm_r(data_area_file_list)
  rescue SystemCallError => e
    raise RuntimeError, "Failed to zero data area: #{e.message}"
  end

  def determine_compression
    Syslog.debug("#{self.class.name}: Checking compression type")
    magic = cmd(get_magic_command, "Fetching magic number", "failed to fetch magic number from #{target_uri_display_name}").to_s
    case
    when magic.unpack('V') == [0x184D2204]
      Syslog.info("#{self.class.name}: Detected lz4 compressed archive")
      @compression_tag = "-Ilz4"
    when magic.unpack('n') == [0x1f8b]
      Syslog.info("#{self.class.name}: Detected gzip compressed archive")
      @compression_tag = "-z"
    else
      Syslog.info("#{self.class.name}: Assuming uncompressed archive")
      @compression_tag = ""
    end
  end

  attr_reader :compression_tag

  def curl_token_option
    token = current_token
    "-H 'X-Auth-Token:#{token}'" if token
  end

  def run_restore
    Syslog.debug "Running restoration process"
    if system(service_running_command)
      run(stop_service_command, "stopped MySQL service", "failed to stop MySQL service")
    end
    zero_data_area
    determine_compression
    run(mys_restore_command, "restored MySQL data area", "failed to restore database from #{target_uri_display_name}")
  end

  def data_action
    run_restore
    @state="completed"
  end

end
