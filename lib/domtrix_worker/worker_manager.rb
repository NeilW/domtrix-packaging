#!/usr/bin/env ruby
#    Brightbox - Machine Message consumer
#    Copyright (C) 2011, Brightbox Systems
#    Author: Neil Wilson
#
#  Listen on a queue and reboot the appropriate customer machine.


class WorkerManager
  # Handle unimplemented Commands

  include MonitorMixin
  include DomtrixConfig

  attr_accessor :statistics_frequency

  DEFAULT_FREQUENCY = 5

  def initialize(command_hash)
    super()
    @command_hash = command_hash
    @command_hash.default = UnknownCommand
    @customer_machine = ENV["MACHINE"]
    Syslog.open("#{File.basename($0)}(#{@customer_machine})", Syslog::LOG_PID)
    if ENV['DEBUG']
      Syslog.mask = Syslog::LOG_UPTO(Syslog::LOG_DEBUG)
    else
      Syslog.mask = Syslog::LOG_UPTO(Syslog::LOG_INFO)
    end
    if @customer_machine.to_s.empty?
      Syslog.err("WorkerManager: #{File.basename $0}: No target details given - aborting")
      abort
    end
    config.load_config
    Syslog.debug(config.load_message)

    @statistics_frequency = DEFAULT_FREQUENCY
    @mq_login = config['mq_login']
    @mq_password = config['mq_password']
    @report_queue = ENV["REPORT_QUEUE"] || ReportPayload.default_queue
    @task_queue = ENV["TASK_QUEUE"] || "/queue/#{@customer_machine}"
    @statistics_topic = ENV["STATISTICS_TOPIC"] || StatisticsPayload.default_topic
    @mq_host_list = config['mq_hosts'].split(',')
    @mq_hosts = create_hash(@mq_host_list.dup)
    @stats = DomtrixStats::StatsProcessor.new(@customer_machine)
    @stats.static_info = YAML::load(ENV["STATIC_INFO"].to_s) || @stats.static_info
    Syslog.info("WorkerManager started for #{@customer_machine} listening on task queue #{@task_queue}")
  end
  
  attr_reader :stats
  attr_reader :customer_machine

  def terminated
    @terminated 
  end

  def trap_terminations
    Signal.trap("TERM") do 
      Syslog.info "WorkerManager: SIGTERM received - completing current task"
      @terminated = true
    end
    Syslog.debug "WorkerManager: TERM signal handling in place" 
  end

  def run_stats
    @stats.tick do |report_name, resource, statistics|
      publish_statistics("/topic/#{report_name}", resource, statistics)
    end
  end

  def run
    connect_or_abort
    Syslog.debug "WorkerManager: Reporting to queue #{@report_queue} by default"
    Syslog.debug "WorkerManager: Subscribing to queue #{@task_queue}"
    trap_terminations
    handle_incoming_messages
    until terminated
      run_stats
      @client.join(statistics_frequency)
    end
    Syslog.debug("WorkerManager: Terminated main statistics loop")
    Syslog.debug("WorkerManager: Running termination statistics")
    @stats.terminate
    run_stats
    Syslog.debug("WorkerManager: Completed termination statistics")
    Syslog.debug("WorkerManager: Waiting for listener to complete")
    synchronize do
      Syslog.debug("WorkerManager: Listener thread complete")
      @client.close
      Syslog.info("WorkerManager: Disconnected - exiting")
    end
  ensure
    Syslog.close
  end

  def report_queue
    @msg.headers["reply-to"] || @report_queue
  end

  def publish_statistics(topic = @statistics_topic, resource = nil, statistics = nil)
    if resource
      Syslog.debug "WorkerManager: Reporting statistics for resource #{resource.to_s}"
      payload = StatisticsPayload.new(:queue => @customer_machine, :resource_id => resource, :statistics => statistics)
      @client.publish(topic, payload.body, payload.headers)
    else
      Syslog.err "WorkerManager: Statistics reported with no associated resource"
    end
  end

private

  def create_hash (host_list)
    host_list.collect! do |host|
      {:host => host, :login => @mq_login, :passcode => @mq_password}
    end
  end

  def report(state)
    Syslog.info "WorkerManager: Reporting #{state.to_s} for task #{@task.id}"
    payload = ReportPayload.new(:id => @task.id, :state => state.to_s)
    @client.publish(report_queue, payload.body, payload.headers(redelivered?))
  end

  def redelivered?
    @msg.headers["redelivered"] == "true"
  end

  def connect_or_abort
    hosts = @mq_hosts.collect { |h| h[:host] }
    if hosts.empty?
      Syslog.err "WorkerManager: Missing @mq_hosts - nothing to connect to"
      abort
    end
    Syslog.info "WorkerManager: Connecting to broker(s): #{@mq_host_list.inspect}"
    # Set max_reconnect_attempts to 16 to ensure we get syslogs about
    # failures once every minute or so
    begin
      @client = Stomp::Client.new(:hosts => @mq_hosts, :randomize => true, :max_reconnect_attempts => 16)
      if @client.connection_frame.command == "CONNECTED"
	Syslog.debug "WorkerManager: Connected:  #{@client.connection_frame.headers["session"]}"
      else
	raise "#{@client.connection_frame.command}: #{@client.connection_frame.headers["message"]}"
      end
    rescue StandardError => e
      Syslog.err "WorkerManager: Failed to connect: #{e.class}: #{e.message}"
      abort
    end
  end

  def handle_incoming_messages
    @client.subscribe(@task_queue, :ack => 'client') do |msg|
      Syslog.debug "WorkerManager: Message received on #{msg.headers['destination']}: #{msg.inspect}"
      Syslog.info "WorkerManager: Message #{msg.headers['message-id']} received on #{msg.headers['destination']}, correlation id #{msg.headers['correlation-id']}"
      @msg = msg
      @task = YAML::load(msg.body) # FIXME: Is this safe to trust?
      Syslog.debug @task.inspect
      command = @command_hash[@task.command].new(@customer_machine, @task.data)
      Syslog.info "WorkerManager: Command initialised: #{command.inspect}"
      report :acknowledged unless redelivered?
      Syslog.info "WorkerManager: Message acknowledged"
      command.statistics_frequency = statistics_frequency
      synchronize do
      	Syslog.debug("WorkerManager: Enter Critical Section")
	command.action do |resource, stats, queue |
	  topic = if queue then "/topic/#{queue}" else @statistics_topic end
	  publish_statistics(topic, resource, stats)
	end
	report command.state
	if command.successful?
	  Syslog.info "WorkerManager: Command successful: clearing message"
	  @client.acknowledge(msg)
	  Syslog.debug "WorkerManager: cleared."
	else
	  Syslog.info "WorkerManager: Command failed: Moving on"
	end
	if terminated
	  @client.unsubscribe(@task_queue)
	  Syslog.debug("WorkerManager: Terminating - Unsubscribed from #{@task_queue}")
	end
	Syslog.debug("WorkerManager: Exit Critical Section")
      end
    end
  end

end
