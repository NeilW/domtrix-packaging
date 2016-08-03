#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2014, Brightbox Systems
#    Author: Neil Wilson
#
#  CloudSQL services Configure command.

class CloudsqlConfigureCommand < DataCommand

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

  def upgrade_weekday
    @data[:upgrade_weekday]
  end

  def upgrade_hour
    @data[:upgrade_hour]
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
    new_hash["pg_service::admin_password"] = admin_password if admin_password
    new_hash["domtrix::ftplogin"] = ftp_login if ftp_login
    new_hash["domtrix::ftppassword"] = ftp_password if ftp_password
    new_hash["domtrix::notify_service"] = 'no'
    new_hash["basic_server::upgrade_hour"] = upgrade_hour if upgrade_hour
    new_hash["basic_server::upgrade_weekday"] = upgrade_weekday if upgrade_weekday
    initial_yaml_hash.merge new_hash
  end

  def write_cloudsql_puppet_config(puppet_hash)
    Syslog.debug "#{self.class.name}: Updating CloudSQL hiera runtime config"
    File.open(runtime_yaml_file,
      File::CREAT|File::TRUNC|File::WRONLY, 0600) do |f|
      YAML.dump(puppet_hash, f)
    end
    Syslog.debug "#{self.class.name}: Updated."
  end

  def start_puppet_run
    Syslog.debug "#{self.class.name}: Starting CloudSQL puppet reconfigure"
    run("puppet-git-reapply #{update_flag} >/dev/null 2>&1", "Puppet manifests reapplied #{update_flag}", "Puppet run failure")
    Syslog.debug "#{self.class.name}: Completed"
  end

  def update_central_config
    Syslog.debug "#{self.class.name}: Updating central config"
    Class.new.extend(DomtrixConfig).config.load_config
  end

  def data_action
    temp_hash = build_puppet_config_hash
    write_cloudsql_puppet_config(temp_hash)
    start_puppet_run
    temp_hash.delete("domtrix::notify_service")
    write_cloudsql_puppet_config(temp_hash)
    update_central_config if (ftp_login || ftp_password)
    @state="completed"
  end

end
