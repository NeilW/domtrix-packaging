#!/usr/bin/env ruby
#  Brightbox - Domtrix Cache command class loader
#  Copyright (c) 2013, Brightbox Systems
#  Author: Neil Wilson

require 'fileutils'
require 'tempfile'
require 'open3'
require 'domtrix_config'
require 'domtrix_core'

target=File.basename(__FILE__, '.rb')
Dir.open(File.join(File.dirname(__FILE__),target)) do |d|
  d.each do |f|
    if f =~ /\.rb$/
      file = File.basename f, '.rb'
      autoload(file.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase },File.join(target,file))
    end
  end
end

#Monkey patch a copy_stream facility in using 'sendfile'
unless IO.respond_to? :copy_stream
  require 'sendfile'

  def IO.copy_stream(src, dst, copy_length=nil, offset=nil)
    current_pos = src.pos
    count = dst.sendfile(src, offset || current_pos, copy_length)
    src.seek(count, IO::SEEK_CUR)
    count
  rescue EOFError
    0
  end
end
