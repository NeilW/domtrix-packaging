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
    "curl --silent --show-error #{target_uri_name} | tar --extract --gzip --directory /var/lib/mysql ."
  end

  def run_restore
    Syslog.debug "Running restoration process"
    run(mys_restore_command, "MySQL restore complete", "failed to restore database from #{target_uri_display_name}")
  end

  def data_action
    run_restore
    @state="completed"
  end

end
