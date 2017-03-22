#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2017, Neil Wilson, Brightbox Systems
#
#  CloudSQL Snapshot command

class CloudsqlSnapshotBase < DataCommand

private

  include RootPrivileges
  include DomtrixConfig
  include CommandRunner
  include CloudsqlUriCommon

  def snapshot_check_command
    "nice curl --silent --show-error --fail --head #{curl_token_option} '#{target_uri_name}'"
  end

  def segment_size
    config['upload_segment_size']
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

  def run_snapshot
    Syslog.debug "Running snapshot process"
    run(backup_command, "Database snapshot complete", "failed to snapshot database to #{target_uri_display_name}")
    run(snapshot_check_command, "Checked snapshot exists", "snapshot has not been created at #{target_uri_display_name}")
  end

  def backup_command
    InitDetector.select(
      "nice systemd-cat cloudsql_backup '#{current_token}' '#{target_uri_name}' '#{volgroup}' #{segment_size}",
      "nice cloudsql_backup '#{current_token}' '#{target_uri_name}' '#{volgroup}' #{segment_size} | logger -t cloudsql_backup"
    )
  end

end
