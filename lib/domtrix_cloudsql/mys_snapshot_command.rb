#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2016, Neil Wilson, Brightbox Systems
#
#  Mysql Snapshot command

class MysSnapshotCommand < CloudsqlSnapshotBase

private
  
  alias data_area mysql_data_area

  def backup_script
    <<-END
#!/bin/sh
logger -t db-snapshot "Snapshotting MySQL database to #{target_uri_display_name}"
nice tar --create --one-file-system --sparse #{compression_tag} --directory /var/cache/mylvmbackup/mnt/backup --exclude-caches-under . --directory .. backup-pos | segment_upload #{token_details} #{segment_size_details} '#{target_uri_name}'
  END
  end

  #All other options control by config file
  def mylvmbackup_command(hook_dir)
    "nice mylvmbackup --hooksdir=#{hook_dir}"
  end

  #LZ4 compression
  def compression_tag
    "-Ilz4"
  end

  def segment_size_details
    segment_size && "--segment-size #{segment_size}B"
  end

  def token_details
    token = current_token
    "--auth-token '#{token}'" if token
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
      run(mylvmbackup_command(dir), "MySQL snapshot complete", "failed to snapshot database to #{target_uri_display_name}")
    end
    run(snapshot_check_command, "Checked snapshot exists", "snapshot has not been created at #{target_uri_display_name}")
  end

end
