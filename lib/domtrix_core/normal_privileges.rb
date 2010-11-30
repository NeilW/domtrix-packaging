#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2010, Brightbox Systems
#    Author: Neil Wilson
#
#  Normal privileges module

module NormalPrivileges
  
  def correct_privileges?
    Process::euid != 0
  end

end
