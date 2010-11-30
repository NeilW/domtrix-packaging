#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2010, Neil Wilson, Brightbox Systems
#
#  Report message payload 

class ReportPayload
  attr_accessor :id, :state, :time
  
  def initialize(params)
    @id = params[:id]
    @state = params[:state]
    @time = params[:time] || Time.now.httpdate
  end

  def action
    task = Task.find(@id)
    task.state = @state
    task.completed_at = Time.httpdate(@time)
    task.save!
  end
 
  def headers(retried = false)
    result = {
      :suppress_content_length => true,
      'persistent' => true,
      'correlation-id' => @id
    }
    result['retried'] = true if retried
    result
  end
   
  def body
    YAML::dump(self)
  end

  def self.default_queue
    "/queue/report"
  end
 
end
