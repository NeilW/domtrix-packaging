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
    Syslog.debug "AbortCommand: Found running command '#{cmd_name}'" unless cmd_name.empty?
    %w(dd uri-cp sparse-expand).include?(cmd_name)
  end

  def kill_job
    Syslog.info "AbortCommand: Killing process group #{jobid}"
    result = Process.kill("-TERM", jobid)
    if result
      Syslog.debug "AbortCommand: Process Group #{jobid} killed (#{result})"
    else
      Syslog.warning "AbortCommand: Could not kill process group #{jobid}"
    end
    @state = "completed"
  end

  def data_action
    if jobid == 1
      Syslog.err "AbortCommand: Refusing to kill init"
      raise "Aborting init wouldn't be sensible now would it..."
    elsif valid_job?
      kill_job
    else
      Syslog.debug "AbortCommand: Process Group #{jobid} is not a long running task."
      Syslog.err "AbortCommand: Process group #{jobid} is not a known job, refusing to kill"
      @state = "permission_denied"
    end
  end

end
