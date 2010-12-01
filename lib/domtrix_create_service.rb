#!/usr/bin/env ruby
#  Brightbox - Machine Message service layout creator
#  Copyright (c) 2010, Brightbox Systems
#  Author: Neil Wilson

require 'optparse' 
require 'ostruct'
require 'date'
require 'etc'

class DomtrixCreateService
  VERSION = '0.0.1'

  attr_reader :options
  attr_accessor :root_required
  attr_accessor :worker_command
  attr_accessor :progname

  def initialize(arguments, stdin)
    @arguments = arguments
    @stdin = stdin
    
    # Set defaults
    @options = OpenStruct.new
    @options.verbose = false
    @options.quiet = false
    @options.memory_limit = 0.25
    @options.user = "root"
    @options.group = "root"
    @options.supervision_dir = "/var/lib/supervise"
    @options.debug = !ENV['DEBUG'].nil?
  end

  # Parse options, check arguments, then process the command
  def run
        
    if parsed_options? && arguments_valid? 
      
      puts "Start at #{DateTime.now}\n\n" if @options.verbose
      
      output_options if @options.verbose # [Optional]
            
      validate_arguments            
      process_command
      
      puts "\nFinished at #{DateTime.now}" if @options.verbose
      
    else
      puts usage
      puts
      puts "For help use: #{@progname} -h"
      
    end
      
  end
  
  protected
  
    def parsed_options?
      
      # Specify options
      opts = OptionParser.new do |opts|
	opts.banner = usage
	opts.separator ""
	opts.separator "Specific options:"
	opts.on('-m', '--memory-limit LIMIT', Integer, 'Set the soft virtual memory limit in MB',"[Default: #{@options.memory_limit}]") do |limit|
	  raise OptionParser::InvalidArgument if limit <= 0
	  @options.memory_limit = limit
	end
	opts.on('-M', '--mq-host HOSTNAME', String, 'FQDN of the Message Queue host') do |hostname|
	  @options.mq_hosts = hostname
	end
	opts.on('-u', '--mq-username USERNAME', String, 'Username to log on the MQ') do |uname|
	  @options.mq_login = uname
	end
	opts.on('-p', '--mq-password PASSWORD', String, 'Password to log on the MQ') do |passwd|
	  @options.mq_password = passwd
	end
	opts.on('--debug', 'Switch on debugging mode') do
	  @options.debug = true
	end
	opts.on('--test', 'Use the test servers') do
	  @options.test = true
	  @options.debug = true
	end
	opts.separator ""
	opts.separator "General options:"
	opts.on_tail('-v', '--version', 'Display the version, then exit')    { output_version ; exit 0 }
	opts.on_tail('-h', '--help', 'Display the help message') do
	  puts opts
	  exit
	end
	opts.on_tail('-V', '--verbose', 'Verbose output')    { @options.verbose = true }  
	opts.on_tail('-q', '--quiet', 'Output as little as possible, overrides verbose')      { @options.quiet = true }
      end
            
      begin
	opts.parse!(@arguments)
	process_options
	true      
      rescue OptionParser::ParseError => ex
        puts ex
	false
      end
        
    end

    # Performs post-parse processing on options
    # quiet overrides verbose.
    # disks override supervision.
    def process_options
      @options.verbose &&= !@options.quiet
    end
    
    def output_options
      puts "Options:\n"
      
      @options.marshal_dump.each do |name, val|        
        puts "  #{name} = #{val}"
      end
    end

    # True if required arguments were provided
    def arguments_valid?
      @arguments.length == 1 
    end

    # Setup the arguments
    def validate_arguments
      is_root? || output_error("must be run as root.")
      supervise_area_exists? || output_error("supervision root directory '#{@options.supervision_dir}' is missing.")
      supervision_in_place? && output_error("Directory '#{target_supervision_dir}' already exists.")
      group_exists? || output_error("group '#{@options.group}' is missing.")
      user_exists? || output_error("user '#{@options.user}' is missing.")
    end

    def supervise_area_exists?
      File.directory?(@options.supervision_dir)
    end

    def supervision_in_place?
      File.exists?(target_supervision_dir)
    end

    def target_supervision_dir
      File.join(@options.supervision_dir, @arguments[0])
    end

    def group_exists?
      @gid = Etc::getgrnam(@options.group).gid
      true
    rescue ArgumentError
      false
    end

    def user_exists?
      @uid = Etc::getpwnam(@options.user).uid
      true
    rescue ArgumentError
      false
    end

    def root_required?
      @root_required
    end

    def is_root?
      Process.euid.zero?
    end

    def output_help
      output_version
      RDoc::usage() #exits app
    end
    
    def usage
      "Usage: #{@progname} [-hVvq] [-m LIMIT] worker-name"
    end

    def output_version
      puts "#{@progname} version #{VERSION}"
    end
    
    def output_error(error)
      puts "#{@progname}: #{error}"
      abort
    end

    def run_command
      <<-END
#!/bin/sh
exec #{'setuidgid '+@options.user unless root_required?} \\
  softlimit -s #{limit_in_bytes} \\
    envdir ./env #{worker_command}
      END
    end

    def limit_in_bytes
      (@options.memory_limit * 1024 ** 2).to_i
    end

    def drop_privileges
      Process.initgroups(@options.user, @gid)
      Process::GID.change_privilege(@gid)
      Process::UID.change_privilege(@uid)
    rescue Errno::EPERM => e
      output_error "couldn't change user and group to #{@options.user}:#{@options.group}."
    end

    def write_env_var(variable, value)
      File.open(File.join(@env_dir, variable),'w', 0750) do |f|
        f.puts value
      end
    end
    
    def process_command
      mode = 0750
      Dir.mkdir(target_supervision_dir, mode)
      File.chown(@uid, @gid, target_supervision_dir)
      unless root_required
        drop_privileges
      end
      @env_dir = File.join(target_supervision_dir, 'env')
      Dir.mkdir(@env_dir, mode)
      write_env_var('MACHINE', @arguments[0])
      write_env_var('MQ_LOGIN', @options.mq_login) if @options.mq_login
      write_env_var('MQ_HOSTS', @options.mq_hosts) if @options.mq_hosts
      write_env_var('MQ_PASSWORD', @options.mq_password) if @options.mq_password
      write_env_var('DEBUG', '1') if @options.debug 
      File.open(File.join(target_supervision_dir, 'run'), 'w', mode) do |f|
        f.write run_command
      end
    end

end
