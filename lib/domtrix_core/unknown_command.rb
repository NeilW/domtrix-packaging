#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2010, Neil Wilson, Brightbox Systems
#
#  Implement the unknown command. Root of all other commands

class UnknownCommand
  
  attr_accessor :target
  attr_accessor :statistics_frequency
  attr_reader :state

  def initialize(target, data = nil)
    @target = target
    @data = data
  end

  def action(&action_block)
    if correct_privileges?
      @state = "fail"
      @action_block = action_block
      target_action
    else
      @state = "permission_denied"
    end
  end

  def action_proc(resource)
    unless @action_block
      Syslog.debug("action proc requested, but no block")
      return nil
    end
    Syslog.debug("Generating action proc from block")
    Proc.new do |stats|
      @action_block.call(resource, stats)
    end
  end

  def target_action
    @state = "unknown_command"
  end

  def successful?
    @state != "fail"
  end

  def completed?
    @state == "completed"
  end

  def uri
    "unix:///localhost"
  end

  def correct_privileges?
    true
  end

  def inspect
    "<#{self.class}:0x#{object_id.to_s(16)} target=#{target}, state=#{state}, @data=#{@data.inspect}>"
  end

end
