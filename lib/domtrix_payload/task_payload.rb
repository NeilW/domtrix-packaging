#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2010, Neil Wilson, Brightbox Systems
#
#  Task message payload

class TaskPayload
  attr_accessor :id, :command, :data
  
  def initialize(params)
    @id = params[:id]
    @command = params[:command]
    @data = params[:data]
  end

  def inspect
    "<#{self.class}:0x#{object_id.to_s(16)} id=#{id}, command=#{command}, data=#{data.inspect}>"
  end
 
end
