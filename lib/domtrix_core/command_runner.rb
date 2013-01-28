#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2010, Brightbox Systems
#    Author: Neil Wilson
#
#  Command runner 

module CommandRunner
  
  def run(command, log_message=nil, raise_message=nil)
    cmd(command, log_message, raise_message)
    $?.success?
  end

  def cmd(command, log_message=nil, raise_message=nil)
    result=`#{command}`
    if $?.success?
      success_log(log_message)
    else
      fail_log(command, log_message, raise_message)
    end
    error_check(raise_message) if raise_message
    result
  end

  def success_log(log_message)
    Syslog.info("#{self.class.name}: #{log_message}") if log_message
  end

  def fail_log(command, log_message=nil, raise_message=nil)
    Syslog.err("#{self.class.name}: Command failed: '#{command}'")
    Syslog.err("#{self.class.name}: should have #{log_message}") if log_message
    if raise_message
      Syslog.err("#{self.class.name}: raising exception: #{raise_message}")
    else
      Syslog.err("#{self.class.name}: continuing...")
    end
  end

  def error_check(raise_message)
    unless $?.success?
      if $?.exited?
        raise RuntimeError, "Exit status #{$?.exitstatus} " + raise_message
      elsif $?.signaled?
        raise RuntimeError, "Terminated by signal #{$?.termsig} " + raise_message
      else
        raise RuntimeError, "Abnormal exit " + raise_message
      end
    end
  end

  def pipe_in(command, input)
    log_message = "piped to #{command} successfully"
    error_message = nil
    IO.popen("#{command} 2>&1", 'w+') do |pipe|
      pipe.syswrite(input)
      pipe.close_write
      error_message = pipe.readline unless pipe.eof?
    end
    if $?.success?
      success_log(log_message)
    else
      fail_log(command + " << " + input, log_message, error_message)
    end
    error_check(error_message) if error_message
  end
    

end
