#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2010, Brightbox Systems
#    Author: Neil Wilson
#
#  Command that use the data element.

class DataCommand < UnknownCommand
  
  def target_action
    if valid_data?
      data_action
    else
      @state = "error: invalid data hash"
    end
  rescue StandardError => e
    Syslog.debug("Rescued exception: #{$!.inspect}: #{e.message}")
    @state = "error: " + e.message
  end

  def valid_data?
    @data &&
    @data.is_a?(Hash) &&
    required_elements_present?
  end

end
