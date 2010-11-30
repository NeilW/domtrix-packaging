#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2010, Brightbox Systems
#    Author: Neil Wilson
#
#  Statistic message shell

class StatisticsPayload
  attr_accessor :queue, :resource_id, :statistics
  
  def initialize(params)
    @queue = params[:queue]
    @resource_id = params[:resource_id]
    @statistics = params[:statistics]
  end

  def headers
    result = {
      :suppress_content_length => true,
      'persistent' => true,
      'queue-name' => @queue,
    }
    result['resource-id'] = @resource_id if @resource_id
    result
  end
   
  def body
    if @statistics
      YAML::dump(@statistics)
    else
      ""
    end
  end

  def self.default_topic
    "/topic/statistics"
  end
 
end
