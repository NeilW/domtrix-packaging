#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2010, Neil Wilson, Brightbox Systems
#
#  Load Balancer Configure command.

class MysConfigureCommand < DataCommand
  
  include RootPrivileges

private

  def required_elements_present?
    admin_password
  end

  def admin_password
    @data[:admin_password]
  end

  def puppet_config_hash
    {
      "admin_password" => admin_password
    }
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


  def write_mysql_puppet_config
    Syslog.debug "Updating Mysql config"
    File.open("/etc/brightbox/mysql-system/config.yaml",
      File::CREAT|File::TRUNC|File::WRONLY, 0600) do |f|
      YAML.dump(puppet_config_hash, f)
    end
    Syslog.debug "Updated."
  end

  def start_puppet_run
    Syslog.debug "Starting MySQL puppet reconfigure"
    run("start brightbox-mysql-system", "Failed to complete puppet run")
    Syslog.debug "Started"
  end

  def data_action
    write_mysql_puppet_config
    start_puppet_run
    @state="completed"
  end

end
