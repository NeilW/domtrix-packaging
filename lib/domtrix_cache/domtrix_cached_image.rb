class DomtrixCachedImage < DomtrixCacheCore

  def initialize(url,options={})
    super(url)
    @options = options
    @config_item = :cache_dir
  end

  def expander
    case File.extname(url_path)
    when ".gz"
      Syslog.info("#{self.class.name}: Gzip compressed source - decompressing")
      "| zcat -f |"
    when ".bz2"
      Syslog.info("#{self.class.name}: Bzip compressed source - decompressing")
      "| bzcat -f |"
    else
      "|"
    end
  end

  def create
    Syslog.info("#{self.class.name}: Downloading from #{@image_url}")
    if execute_download
      commit
      Syslog.debug("#{self.class.name}: Downloaded")
    else
      clear_up_write_path
      raise error_class, "Failed to create cached image from #{@image_url}: #{@curl_error}"
    end
  rescue StandardError => e
    Syslog.debug("#{self.class.name}: Create failed: #{e.message}")
    clear_up_write_path
    raise error_class, e.message
  end

  def optimise
    if exist?
      Syslog.info("#{self.class.name}: running optimise on #{path}")
      system("nohup optimise-cache #{path} >/dev/null 2>&1&")
      Syslog.debug("#{self.class.name}: Optimiser started")
    end
  end

  def obtain_local_file
    if exist?
      yield path
    else
      create
      yield path
      optimise
    end
  end

private
 
  def execute_download
    Syslog.debug("#{self.class.name}: Initial download")
    return true if run_curl_command
    Syslog.debug("#{self.class.name}: Download failed. Pruning cache.")
    cache.prune
    Syslog.debug("#{self.class.name}: Second download attempt")
    return true if run_curl_command
    Syslog.debug("#{self.class.name}: Download failed. Clearing cache.")
    cache.clean
    Syslog.debug("#{self.class.name}: Third and final download attempt")
    return true if run_curl_command
    false
  end

  def curl_copy_command
    "curl -f -s -S #{headers} #{@logon} #{@image_url} #{expander} cp --sparse=always /dev/stdin #{write_path}"
  end

end
