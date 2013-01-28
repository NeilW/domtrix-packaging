#!/usr/bin/env ruby
#	Brightbox - Statistic reporting classes
#	Copyright (C) 2011, Brightbox Systems
#	Author: Neil Wilson
#
# Statistics Processor - runs a queue of objects and returns output if any.

module DomtrixStats
  class StatsProcessor
    
    def initialize machine
      @machine = machine
      @static_info = {}
      @stats_list = []
    end

    attr_accessor :static_info
    attr_reader :machine
    attr_reader :stats_list

    def push stats_object
      @stats_list << stats_object
    end

    def terminate
      @terminate = true
    end

    def terminated?
      @terminate
    end

    def tick(&stats_handler)
      Syslog.debug("#{self.class.name}: Processing tick")
      @stats_list.each do |stats_object|
        stats_object.current_domain { current_domain }
	stats_object.terminate if terminated?
	Syslog.debug("#{self.class.name}: Ticking #{stats_object.name}")
	stats_object.tick do |topic, stats|
	  stats = @static_info.merge(stats) if stats_object.send_static_info?
	  Syslog.info("#{self.class.name}: Stats generated for topic #{topic}")
	  stats_handler.call(topic, @machine, stats)
	end
      end
    rescue Libvirt::Error => e
      Syslog.notice("#{self.class.name}: Libvirt error: " + e.libvirt_message)
    ensure
      close_domain
    end

  private 

    def current_domain
      @guest ||= conn.lookup_domain_by_name(@machine)
    rescue Libvirt::RetrieveError
      Syslog.debug("#{self.class.name}: Unable to find running domain #{@machine}")
      @guest = nil
    end

    def close_domain
      @guest && @guest.free
      @guest = nil
      close
    end

    def conn
      Syslog.debug("#{self.class.name}: Opening Statistics Libvirt connection") unless @conn
      @conn ||= Libvirt.open("")
    end

    def close
      if @conn
        @conn.close
	@conn = nil
	Syslog.debug("#{self.class.name}: Statistics Libvirt connection disconnected")
      end
    end

  end
end
