class DomtrixCacheCore < DomtrixUriBase

  include DomtrixConfig

  def path
    @cache_path ||= File.join(cache.cache_dir, basename)
  end

  attr_reader :config_item

  def exist?
    File.readable?(path)
  end

  def clear
    Syslog.debug("#{self.class.name}: Clearing image cache completely")
    cache.clean
  end

  def destroy
    if exist?
      Syslog.debug("#{self.class.name}: Removing cached image for #{@image_url}")
      zap
    end
    if exist?
      Syslog.notice("#{self.class.name}: Using basic unconditional forced remove on #{path}")
      zap!
    end
  end

  def zap!
    FileUtils.rm_f path
  end

  def zap
    zap!
  end

  def clear_up_write_path
    if File.exists?(write_path)
      Syslog.debug("#{self.class.name}: clearing up write path")
      File.unlink(write_path)
    end
  rescue StandardError => e
    Syslog.debug("#{self.class.name}: Exception while clearing up write path - ignoring")
  end

  def write_path
    @write_path ||= get_temp_filename(File.join(cache.write_dir, basename))
  end

  def commit
    Syslog.debug("#{self.class.name}: Moving #{basename} to read cache")
    cache.commit(write_path, basename)
  end

  def cache
    @cache ||= create_cache
  end

private

  def create_cache
    Syslog.debug("#{self.class.name}: Initialising local cache")
    Syslog.debug("#{self.class.name}: from config item '#{config_item.inspect}'") if config_item
    if config_item && config[config_item]
      ImageCache.new(config[config_item], config[:cache_max_blocks])
    else
      raise "Missing configuration for #{config_item.inspect}"
    end
  end

  def get_temp_filename(filename)
    temp = Tempfile.new(File.basename(filename), File.dirname(filename))
    temp.close
    temp.path+'-new'
  end

  def headers
    "-H X-Auth-Token:#{@options['auth_token']}" if @options['auth_token']
  end

end
