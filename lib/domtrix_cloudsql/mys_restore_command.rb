#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2013, Neil Wilson, Brightbox Systems
#
#  Mysql Restore Command

class MysRestoreCommand < CloudsqlRestoreCommand

private

  alias data_area mysql_data_area
  alias service_name mysql_service_name

end
