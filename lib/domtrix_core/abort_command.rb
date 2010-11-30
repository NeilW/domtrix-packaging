#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2010, Brightbox Systems
#    Author: Neil Wilson
#
# Abort a long running task

class AbortCommand < DataCommand
  
private

  def valid_data?
    @data &&
    !@data.empty? &&
    !@data.to_i.zero?
  end

  def jobid
    @data.to_i
  end

  def valid_job?
    cmd_name = `ps -p #{jobid} -o comm=`.chomp
    Syslog.debug "Found running command '#{cmd_name}'" unless cmd_name.empty?
    %w(dd uri-cp sparse-expand).include?(cmd_name)
  end

  def kill_job
    Syslog.debug "Attempting to kill Process Group #{jobid}"
    result = Process.kill("-TERM", jobid)
    Syslog.debug "Process Group #{jobid} killed (#{result}) "
    @state = "completed"
  end

  def data_action
    if jobid == 1
      raise "Aborting init wouldn't be sensible now would it..."
    elsif valid_job?
      kill_job
    else
      Syslog.debug "Process Group #{jobid} is not a long running task."
      @state = "permission_denied"
    end
  end

end
