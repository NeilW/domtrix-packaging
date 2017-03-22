#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2017, Neil Wilson, Brightbox Systems
#
#  Postgres Snapshot command

class PgSnapshotCommand < CloudsqlSnapshotBase

private

  alias data_area postgres_data_area
  alias volgroup mysql_volgroup

end
