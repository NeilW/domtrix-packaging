#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2016, Neil Wilson, Brightbox Systems
#
#  Mysql Restore Command

class MysRestoreCommand < CloudsqlRestoreBase

private

  alias data_area mysql_data_area
  alias service_name mysql_service_name

end
