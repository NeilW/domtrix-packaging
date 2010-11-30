#!/usr/bin/env ruby
#	Brightbox - Statistic reporting classes
#	Copyright (C) 2010, Brightbox Systems
#	Author: Neil Wilson
#
# Simple keepalive class - triggers every minute

module DomtrixStats
  class Keepalive

    def initialize
      @trigger_time = Time.now
    end

    def action
      if triggered?
	@trigger_time = Time.now + 60
	yield nil, nil
      end
    end

    def triggered?
      Time.now >= @trigger_time
    end

  end
end
