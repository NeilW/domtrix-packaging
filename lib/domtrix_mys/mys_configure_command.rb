#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2010, Neil Wilson, Brightbox Systems
#
#  Load Balancer Configure command.

class MysConfigureCommand < DataCommand

private
  
  include RootPrivileges
  include CommandRunner

  def required_elements_present?
    admin_password
  end

  def admin_password
    @data[:admin_password]
  end

  def puppet_config_hash
    {
      "mys_service::admin_password" => admin_password
    }
  end

  def write_mysql_puppet_config
    Syslog.debug "Updating Mysql hiera runtime config"
    File.open("/etc/brightbox/hiera/runtime.yaml",
      File::CREAT|File::TRUNC|File::WRONLY, 0600) do |f|
      YAML.dump(puppet_config_hash, f)
    end
    Syslog.debug "Updated."
  end

  def start_puppet_run
    Syslog.debug "Starting MySQL puppet reconfigure"
    run("puppet-git-reapply", "Puppet manifests reapplied", "Puppet run failure")
    Syslog.debug "Completed"
  end

  def data_action
    write_mysql_puppet_config
    start_puppet_run
    @state="completed"
  end

end
