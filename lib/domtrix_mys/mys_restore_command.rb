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
    "nice curl --silent --show-error #{target_uri_name} | tar --extract #{compression_tag} --directory #{data_area} ."
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

  def run_restore
    Syslog.debug "Running restoration process"
    if system(service_running_command)
      run(stop_service_command, "stopped MySQL service", "failed to stop MySQL service")
    end
    zero_data_area
    run(mys_restore_command, "restored MySQL data area", "failed to restore database from #{target_uri_display_name}")
  end

  def data_action
    run_restore
    @state="completed"
  end

end
