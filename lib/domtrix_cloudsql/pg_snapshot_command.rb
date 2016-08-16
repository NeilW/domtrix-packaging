#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2016, Neil Wilson, Brightbox Systems
#
#  Postgres Snapshot command

class PgSnapshotCommand < CloudsqlSnapshotBase 

private
  
  alias data_area postgres_data_area

  def pgbackup_command
    InitDetector.select(
      "nice systemd-cat pg_backup #{current_token} '#{target_uri_name}' #{segment_size}",
      "nice pg_backup #{current_token} '#{target_uri_name}' #{segment_size} | logger -t pg_backup"
    )
  end

  def run_snapshot
    Syslog.debug "Running snapshot process"
    run(pgbackup_command, "Database snapshot complete", "failed to snapshot database to #{target_uri_display_name}")
    run(snapshot_check_command, "Checked snapshot exists", "snapshot has not been created at #{target_uri_display_name}")
  end

end
