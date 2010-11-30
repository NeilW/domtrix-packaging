#!/usr/bin/env ruby
#    Brightbox - Setup relative environment
#    Copyright (C) 2010, Brightbox Systems
#    Author: Neil Wilson
#
#  Setup a relative environment if a package manager hasn't set something
#  more specific

begin
  require 'rubygems'
rescue LoadError
end
rootdir = File.expand_path(File.join(File.dirname(__FILE__)))
$: << File.join(rootdir,"lib")
ENV['PATH']+=":#{File.join(rootdir,'bin')}"
DATADIR = File.join(rootdir, 'data/domtrix-lb')
CONFDIR = File.join(rootdir, 'conf')
