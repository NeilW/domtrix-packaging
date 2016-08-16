#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2016, Neil Wilson, Brightbox Systems
#
#  Postgres Restore Command

class PgRestoreCommand < CloudsqlRestoreBase

private

  alias data_area postgres_data_area
  alias service_name postgres_service_name

end
