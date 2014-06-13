class UriCp
  
  include DomtrixConfig

  def initialize(from, to, options={})
    @from = from
    @to = to
    @options = options
    open_syslog
    validate_parameters
    if valid?
      @from = DomtrixUri.new(@from,config)
      @to = DomtrixUri.new(@to,config)
    end
  end

  def validate_parameters
    Syslog.debug("#{self.class.name}: From: #{@from}, To: #{@to}, Options: #{@options.inspect}")
    @error = "From should be valid absolute URI" unless @from =~ URI.regexp
    @error = "To should be valid absolute URI" unless @to =~ URI.regexp
    @error = "Need HTTP(S) URI with auth token" unless
	!@options['auth_token'] ||
    	[@to, @from].any? {|uri| uri[/^https?:/]}
  end

  attr_reader :error, :from, :to

  def valid?
    @error.nil?
  end

  def lvm_directory
    '/dev/servers'
  end

  def qcow_directory
    cache_dir = config['cache_dir']||raise("No cache dir set - can't locate qcow servers")
    File.join(cache_dir, 'servers')
  end

  def open_syslog
    Syslog.open(File.basename($PROGRAM_NAME), Syslog::LOG_PID)
    Syslog.mask = Syslog::LOG_UPTO(Syslog::LOG_DEBUG)
  end

  def select_from_strategy
    case @from.scheme
    when 'file'
      case File.dirname(@from.path)
      when lvm_directory
	Syslog.debug("Selected LVM Snapshot for #{@from}")
        @source = DomtrixLvmSnapshot.new(@from)
      when qcow_directory
	Syslog.debug("Selected QCOW Snapshot for #{@from}")
        @source = DomtrixQcowSnapshot.new(@from)
      else
        Syslog.debug("Selected Local File Cache source for #{@from}")
	@source = DomtrixFileImage.new(@from)
      end
    else
      Syslog.debug("Selected curl transfer to cache for #{@from}")
      @source = DomtrixCachedImage.new(@from, @options)
    end
  end

  def select_to_strategy
    case @to.scheme
    when 'file'
      case File.dirname(@to.path)
      when lvm_directory
	Syslog.debug("Selected LVM target for #{@to}")
        @destination = DomtrixLvmVolume.new(@to)
      when qcow_directory
	Syslog.debug("Selected QCOW target for #{@to}")
        @destination = DomtrixQcowVolume.new(@to)
      else
        Syslog.debug("Selected Local File Cache target for #{@to}")
	@destination = DomtrixFileVolume.new(@to)
      end
    else
      Syslog.debug("Selected curl transfer for #{@to}")
      @destination = DomtrixUriImage.new(@to, @options)
    end
  end

  def run
    config.load_config
    Syslog.debug("#{self.class.name}: #{config.load_message}")
    Syslog.debug("Selecting image copy scheme")
    select_from_strategy
    select_to_strategy
    unless @error
      @source.obtain_local_file do |local_file|
        @destination.create_from local_file
      end
    end
  rescue => e
    @error = e.message
  end
      
end
