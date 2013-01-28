#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2010, Neil Wilson, Brightbox Systems
#
#  Load Balancer Configure command.

class MysSnapshotCommand < DataCommand
  
  include RootPrivileges
  include DomtrixConfig
  include CommandRunner

private

  def target_uri_name
    @targeturi ||= URI(@data[:targeturi])
    add_ftp_credentials(@targeturi) if missing_ftp_credentials?(@targeturi)
    @targeturi
  rescue URI::InvalidURIError
    raise "Invalid Target URI: #{target_uri_display_name}"
  end

  def target_uri_display_name
    if @target_vol
      @target_vol.display_uri
    else
      strip_credentials(@targeturi) if @targeturi
    end
  end

  def required_elements_present?
    target_uri_name
  end

  def strip_credentials(uri_ref)
    local_uri = uri_ref.dup
    local_uri.user = nil
    local_uri.password = nil
    local_uri.to_s
  end

  def missing_ftp_credentials?(uri_name)
    uri_name.scheme == 'ftp' && uri_name.user.nil?
  end

  def add_ftp_credentials(uri_name)
    uri_name.user = config['ftp_login']
    uri_name.password = config['ftp_password']
  end

  def backup_script
    <<-END
#!/bin/sh
logger -t db-snapshot "Snapshotting MySQL database to #{target_uri_display_name}"
tar -C /var/cache/mylvmbackup/mnt -cz backup backup-pos | curl -s -T - --ftp-create-dirs "#{target_uri_name}"
  END
  end

  def mylvmbackup_command(hook_dir)
    "mylvmbackup --log_method=syslog --xfs --backuptype=none --innodb_recover --skip_flush_tables --thin --hooksdir=#{hook_dir}"
  end

  def run_snapshot
    Syslog.debug "Running snapshot process"
    Dir.mktmpdir do |dir|
      File.open(File.join(dir, 'prebackup'),
        File::CREAT|File::WRONLY|File::TRUNC,
	0700
      ) do |f|
        f.puts backup_script
      end
      run(mylvmbackup_command(dir), "MySQL snapshot complete")
    end
  end

  def data_action
    run_snapshot
    @state="completed"
  end

end
