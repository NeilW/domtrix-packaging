#	Brightbox - Command processor classes
#	Copyright (c) 2016, Brightbox Systems
#	Author: Neil Wilson
#
# Module to select and cache a class based on the init system

module InitDetector

  def self.select(systemd, upstart)
    if run("which systemctl >/dev/null 2>&1")
      systemd
    else
      upstart
    end
  end

private

  extend CommandRunner

end
    


