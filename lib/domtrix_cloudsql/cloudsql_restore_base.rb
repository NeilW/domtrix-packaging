#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2013, Neil Wilson, Brightbox Systems
#
#  Cloudsql Restore Command

class CloudsqlRestoreCommand < DataCommand

private
  
  include RootPrivileges
  include DomtrixConfig
  include CommandRunner
  include CloudsqlUriCommon

  def cloudsql_restore_command
    "nice curl --silent --show-error --fail #{curl_token_option} #{target_uri_name} | tar --extract #{compression_tag} --absolute-names --directory #{data_area} ."
  end

  def get_magic_command
    "nice curl -r0-3 --silent --show-error --fail #{curl_token_option} #{target_uri_name}"
  end

  def service_running_command
    InitDetector.select(
      "systemctl is-active --quiet #{service_name}",
      "status #{service_name} 2>/dev/null | grep -q running"
    )
  end

  def stop_service_command
    InitDetector.select(
      "systemctl stop #{service_name}*",
      "stop --quiet #{service_name}"
    )
  end

  def zero_data_area
    Syslog.info("#{self.class.name}: Zeroing CloudSQL data area - #{data_area}")
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

  def run_restore
    Syslog.debug "Running restoration process"
    if system(service_running_command)
      run(stop_service_command, "stopped CloudSQL service", "failed to stop CloudSQL service")
    end
    zero_data_area
    determine_compression
    run(cloudsql_restore_command, "restored CloudSQL data area", "failed to restore database from #{target_uri_display_name}")
  end

  def data_action
    run_restore
    @state="completed"
  end

end
