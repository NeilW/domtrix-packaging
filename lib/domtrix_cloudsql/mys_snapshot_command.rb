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
nice tar --create --one-file-system --sparse #{compression_tag} --directory /var/cache/mylvmbackup/mnt/backup --exclude-caches-under . --directory .. backup-pos | segment_upload #{token_details} #{segment_size_details} '#{target_uri_name}'
  END
  end

  #All other options control by config file
  def mylvmbackup_command(hook_dir)
    "nice mylvmbackup --hooksdir=#{hook_dir}"
  end

  def snapshot_check_command
    "nice curl --silent --show-error --fail --head #{curl_token_option} '#{target_uri_name}'"
  end

  #LZ4 compression
  def compression_tag
    "-Ilz4"
  end

  def segment_size
    config['upload_segment_size']
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

  def gather_statistics
    Syslog.debug "Gathering filesystem statistics for #{data_area}"
    @statistics = {
      :snapshot_name => target_uri_name.path,
      :db_size => database_file_size
    }
  end

  def as_args(str_array)
    str_array && !str_array.empty? && "'#{str_array.join("' '")}'"
  end

  def database_file_size
    `nice du --summarize --total --one-file-system --block-size=1M #{as_args(data_area_normal_files)}`.split.at(-2).to_i
  end

  def report_statistics
    Syslog.info "Reporting snapshot size as #{@statistics[:db_size]}Mb"
    @action_block.call(image_identifier, @statistics, nil)
  end

  def data_action
    gather_statistics
    run_snapshot
    report_statistics
    @state="completed"
  end

end