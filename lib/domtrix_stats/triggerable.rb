#!/usr/bin/env ruby
#	Brightbox - Statistic reporting classes
#	Copyright (C) 2011, Brightbox Systems
#	Author: Neil Wilson
#
# Triggerable mixin

module DomtrixStats::Triggerable

  attr_reader :trigger_time

  def terminate
    @terminate = true
  end

protected

  def initialize(interval = 0)
    trigger_after(interval)
  end

  def trigger_after(seconds)
    @trigger_time = Time.now + seconds
  end
  
  def triggered?
    terminated? || Time.now >= @trigger_time
  end

  def terminated?
    @terminate
  end

  def timestamp
    Time.now.utc.iso8601
  end

end
