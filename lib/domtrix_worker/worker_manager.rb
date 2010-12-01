#!/usr/bin/env ruby
#    Brightbox - Machine Message consumer
#    Copyright (C) 2010, Neil Wilson, Brightbox Systems
#
#  Listen on a queue and reboot the appropriate customer machine.

#Patch Stomp::Client join command so it works properly.

module Stomp
  class Client
    def join(limit = nil)
      @listener_thread.join(limit)
    end
  end
end

class WorkerManager
  # Handle unimplemented Commands

  attr_accessor :statistics_frequency

  DEFAULT_FREQUENCY = 15

  def initialize(command_hash)
    @command_hash = command_hash
    @command_hash.default = UnknownCommand
    @customer_machine = ENV["MACHINE"]
    Syslog.open("#{@customer_machine}", Syslog::LOG_PID)
    Syslog.mask = Syslog::LOG_UPTO(Syslog::LOG_DEBUG)
    if @customer_machine.to_s.empty?
      Syslog.debug("#{File.basename $0}: No target details given - aborting")
      abort
    end
    Syslog.debug(QueueConfig.load_config)

    @statistics_frequency = DEFAULT_FREQUENCY
    @mq_login = QueueConfig.read('mq_login')
    @mq_password = QueueConfig.read('mq_password')
    @report_queue = ENV["REPORT_QUEUE"] || ReportPayload.default_queue
    @task_queue = ENV["TASK_QUEUE"] || "/queue/#{@customer_machine}"
    @statistics_topic = ENV["STATISTICS_TOPIC"] || StatisticsPayload.default_topic
    @mq_hosts = create_hash(QueueConfig.read('mq_hosts').split(','))
    @stats = DomtrixStats::Keepalive.new
  end
  
  attr_accessor :stats
  attr_reader :customer_machine

  def run
    connect_or_abort
    Syslog.debug "Reporting to queue #{@report_queue} by default"
    Syslog.debug "Subscribing to queue #{@task_queue}"
    handle_incoming_messages
    while @client.running
      @stats.action do |resource, statistics|
	publish_statistics(resource, statistics)
      end
      @client.join(statistics_frequency)
    end
  ensure
    @client && @client.close
    Syslog.close
  end

  def report_queue
    @msg.headers["reply-to"] || @report_queue
  end

  def publish_statistics(resource = nil, statistics = nil)
    if resource
      Syslog.debug "Reporting statistics for resource #{resource.to_s}"
    else
      Syslog.debug "Sending keepalive on stats channel"
    end
    payload = StatisticsPayload.new(:queue => @customer_machine, :resource_id => resource, :statistics => statistics)
    @client.publish(@statistics_topic, payload.body, payload.headers)
  end

private

  def create_hash (host_list)
    host_list.collect! do |host|
      {:host => host, :login => @mq_login, :passcode => @mq_password}
    end
  end

  def report(state)
    Syslog.debug "Reporting #{state.to_s} for task #{@task.id}"
    payload = ReportPayload.new(:id => @task.id, :state => state.to_s)
    @client.publish(report_queue, payload.body, payload.headers(redelivered?))
  end

  def redelivered?
    @msg.headers["redelivered"] == "true"
  end

  def connect_or_abort
    hosts = @mq_hosts.collect { |h| h[:host] }
    if hosts.empty?
      Syslog.err "Missing @mq_hosts - nothing to connect to"
      abort
    end
    Syslog.debug "Connecting to broker(s): #{@mq_hosts.inspect}"
    # Set max_reconnect_attempts to 16 to ensure we get syslogs about
    # failures once every minute or so
    begin
      @client = Stomp::Client.new(:hosts => @mq_hosts, :randomize => true, :max_reconnect_attempts => 16)
      if @client.connection_frame.command == "CONNECTED"
	Syslog.debug "Connected:  #{@client.connection_frame.headers["session"]}"
      else
	raise "#{@client.connection_frame.command}: #{@client.connection_frame.headers["message"]}"
      end
    rescue StandardError => e
      Syslog.err "Failed to connect: #{e.class}: #{e.message}"
      abort
    end
  end

  def handle_incoming_messages
    @client.subscribe(@task_queue, :ack => 'client') do |msg|
      Syslog.debug "Message received on #{msg.headers['destination']}: #{msg.inspect}"
      @msg = msg
      @task = YAML::load(msg.body) # FIXME: Is this safe to trust?
      Syslog.debug @task.inspect
      command = @command_hash[@task.command].new(@customer_machine, @task.data)
      Syslog.debug "Command initialised: #{command.inspect}"
      report :acknowledged unless redelivered?
      Syslog.debug "Message acknowledged"
      command.statistics_frequency = statistics_frequency
      command.action do |resource, stats|
        publish_statistics(resource, stats)
      end
      report command.state
      if command.successful?
	Syslog.debug "Command successful: clearing message"
	@client.acknowledge(msg)
	Syslog.debug "cleared."
      else
	Syslog.debug "Command failed: Moving on"
      end
    end
  end

end
