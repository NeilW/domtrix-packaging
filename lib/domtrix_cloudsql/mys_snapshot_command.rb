#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2017, Neil Wilson, Brightbox Systems
#
#  Mysql Snapshot command

class MysSnapshotCommand < CloudsqlSnapshotBase

private

  alias data_area mysql_data_area
  alias volgroup mysql_volgroup

end
