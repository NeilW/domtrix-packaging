#!/usr/bin/env ruby
#    Brightbox - Send message command line library
#    Copyright (C) 2010, Neil Wilson, Brightbox Systems
#
require 'socket'
require 'stomp'
require 'time'

require 'array_shuffle'
require 'domtrix_payload'
require 'domtrix_config'

class DomtrixQueue

include DomtrixConfig

DEFAULT_REPORT_QUEUE = '/queue/CLI.report.'+$$.to_s

def make_queue_hosts
  @queue_hosts = create_hash(config['mq_hosts'].split(','))
end

def initialize(queue_name, report_queue = DEFAULT_REPORT_QUEUE)
  config.load_config
  @mq_login = config['mq_login']
  @mq_password = config['mq_password']
  @id = 1001
  @task_queue = "/queue/#{queue_name}"
  @report_queue = ENV["report_queue"] || report_queue
  make_queue_hosts
  connect_or_abort
  warn "Sending messages to queue #{@task_queue}"
end

def execute(command, data, message)
  @id = rand(1000)
  elements = [].push(data).flatten
  results=[]
  elements.each do |item|
    payload = TaskPayload.new(:id => @id, :command => command, :data => item)
    payload_body = YAML.dump(payload)
    warn "Task #{payload.id}: #{message}"
    warn "Sending #{payload_body}"
    @client.publish(@task_queue, payload_body, default_headers(payload))
    results.push @id
    @id += 1
  end
  warn "Reading reports from queue #{@report_queue}"
  @client.subscribe(@report_queue) do |msg|
    @report = ReportPayload
    @report = YAML::load(msg.body) 
    warn "Report for #{@report.id}: #{@report.state}"
    results.delete(@report.id) unless @report.state == 'acknowledged' 
    abort if results.empty?
  end
  @client.join
end

private

def default_headers(payload)
  {
    :suppress_content_length => true,
    :persistent => true,
    'reply-to' => @report_queue,
    'correlation-id' => payload.id,
    :expires => expire_in(5)
  }
end

def connect_or_abort
  warn "Connecting to broker on URI #{@queue_hosts.inspect}"
  @client = Stomp::Client.new(:hosts => @queue_hosts)
  if @client.connection_frame.command == "CONNECTED"
    warn "Connected:  #{@client.connection_frame.headers["session"]}"
  else
    abort "Failed to connect: #{@client.connection_frame.command}: #{@client.connection_frame.headers["message"]}"
  end
end

def expire_in(minutes)
  ((Time.now+minutes*60).to_f*1000).to_i
end

def create_hash (host_list)
  host_list.collect! do |host|
    {
      :host => host,
      :login => @mq_login,
      :passcode => @mq_password,
      :port => Stomp::Connection::default_port(false)
    }
  end
end

end
