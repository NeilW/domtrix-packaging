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
    true
  end

  def runtime_yaml_file
    "/etc/brightbox/hiera/runtime.yaml"
  end

  def initial_yaml_hash
    @initial_yaml ||= YAML.load_file(runtime_yaml_file)
  rescue SystemCallError => e
    Syslog.debug("#{self.class.name}: YAML load failure - #{e.message}")
    @initial_yaml = {}
  end

  def admin_password
    @data[:admin_password]
  end
  
  def ftp_login
    @data[:ftp_user]
  end

  def ftp_password
    @data[:ftp_password]
  end

  def update_flag
    if @data[:update]
      "--update"
    else
      ""
    end
  end
      

  def build_puppet_config_hash
    new_hash = {}
    new_hash["mys_service::admin_password"] = admin_password if admin_password
    new_hash["domtrix::ftplogin"] = ftp_login if ftp_login
    new_hash["domtrix::ftppassword"] = ftp_password if ftp_password
    initial_yaml_hash.merge new_hash
  end

  def write_mysql_puppet_config(puppet_hash)
    Syslog.debug "Updating Mysql hiera runtime config"
    File.open(runtime_yaml_file,
      File::CREAT|File::TRUNC|File::WRONLY, 0600) do |f|
      YAML.dump(puppet_hash, f)
    end
    Syslog.debug "Updated."
  end

  def start_puppet_run
    Syslog.debug "Starting MySQL puppet reconfigure"
    run("puppet-git-reapply #{update_flag}", "Puppet manifests reapplied #{update_flag}", "Puppet run failure")
    Syslog.debug "Completed"
  end

  def data_action
    temp_hash = build_puppet_config_hash
    write_mysql_puppet_config(build_puppet_config_hash)
    start_puppet_run
    @state="completed"
  end

end
