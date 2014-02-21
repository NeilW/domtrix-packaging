#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2013, Neil Wilson, Brightbox Systems
#
#  Mysql Snapshot command

class MysSnapshotCommand < DataCommand

private
  
  include RootPrivileges
  include DomtrixConfig
  include CommandRunner
  include MysUriCommon

  def backup_script
    <<-END
#!/bin/sh
logger -t db-snapshot "Snapshotting MySQL database to #{target_uri_display_name}"
nice tar --create --one-file-system --sparse #{compression_tag} --directory /var/cache/mylvmbackup/mnt/backup --exclude-caches-under . --directory .. backup-pos | curl --silent --show-error --upload-file - --ftp-create-dirs "#{target_uri_name}"
  END
  end

  def mylvmbackup_command(hook_dir)
    "nice mylvmbackup --log_method=syslog --xfs --backuptype=none --innodb_recover --skip_flush_tables --thin --hooksdir=#{hook_dir}"
  end

  def snapshot_check_command
    "nice curl --silent --show-error --head #{target_uri_name}"
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

  def gather_statistics
    Syslog.debug "Gathering filesystem statistics for #{data_area}"
    sql_stats = FileSystem.stat(data_area)
    @statistics = {
      :snapshot_name => target_uri_name.path,
      :db_size => ((sql_stats.blocks-sql_stats.blocks_free)*sql_stats.block_size/1048576.0).ceil - temp_dir_size
    }
  end

  def as_args(str_array)
    str_array && !str_array.empty? && "'#{str_array.join("' '")}'"
  end

  def temp_dir_size
    `nice du --summarize --total --one-file-system --block-size=1M #{as_args(data_area_cachedirs)}`.split.at(-2).to_i
  end

  def report_statistics
    Syslog.info "Reporting snapshot size as #{@statistics[:db_size]}Mb"
    @action_block.call(target, @statistics, nil)
  end

  def data_action
    gather_statistics
    run_snapshot
    report_statistics
    @state="completed"
  end

end
