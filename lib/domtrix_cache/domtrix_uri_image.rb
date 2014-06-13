class DomtrixUriImage < DomtrixCacheCore

  include DomtrixQemuTools

  def initialize(url, options={})
    super(url)
    @options = options
    @config_item = :snapshot_cache_dir
    @upload_segment_size = config['upload_segment_size']
    @qcow_compression = config['qcow_compression'] && '-c'
    Syslog.warning("#{self.class.name}: 'upload_segment_size' config missing - large upload detection is *off*") unless @upload_segment_size
    Syslog.debug("#{self.class.name}: Qcow compression is #{@qcow_compression?'on':'off'}")
  end

  def create_from(local_file)
    Syslog.debug("#{self.class.name}: Checking accessibility of #{local_file}")
    File.open(local_file, 'r') {}
    Syslog.debug("#{self.class.name}: Transferring...")
    generate_uploadable_snapshot(local_file)
    upload_snapshot
  ensure
    destroy
  end

  def generate_uploadable_snapshot(source)
    Syslog.debug("#{self.class.name}: Source is #{source.inspect}. Stream check is #{stream?(source)}")
    if stream?(source)
      Syslog.debug("#{self.class.name}: Stream detected - uploading from source")
      @target = source
    elsif empty_input_file?(source)
      Syslog.debug("#{self.class.name}: Zero length input file - working around qemu-img bug")
      @target = path
      File.open(@target, 'w') {}
    elsif independent_qcow2_file?(source)
      Syslog.debug("#{self.class.name}: Independent Qcow2 file detected - uploading from source")
      @target = source
    else
      @target = path
      qemu_convert(source, path, "-O qcow2 #{@qcow_compression}")
    end
  rescue => e
    raise error_class, e.message
  end
    
private
  
  BLOCK_SIZE=1048576
  
  def empty_input_file?(source)
    input_file_details = File.stat(source)
    !input_file_details.blockdev? && input_file_details.zero?
  end

  def independent_qcow2_file?(source)
    details=qemu_image_info(source)
    !details['backing file'] && details['file format'] == 'qcow2'
  end

  def large_upload?
    @options['auth_token'] && @upload_segment_size && (
      stream?(@target) || File.stat(@target).size > @upload_segment_size)
  end

  def upload_snapshot
    if large_upload?
      segmented_upload
    else
      run_curl_command_or_raise(full_curl_copy_command(@target))
    end
  end

  def run_curl_command_or_raise(curl_command)
    run_curl_command(curl_command) ||
      raise(error_class,
	"Failed to transfer to #{@image_url}: #{@curl_error}")
  end

  def segmented_upload
    Syslog.debug("#{self.class.name}: Large upload detected - segmenting into #{@upload_segment_size} byte chunks.")
    suffix=1
    File.open(@target) do |f|
      until f.eof?
	segment_name = sprintf("#{@image_url}/%010d", suffix)
	Syslog.debug("#{self.class.name}: Uploading segment #{suffix} from #{@target}")
	upload_segment(f, segment_name)
	suffix=suffix.next
      end
    end
    run_curl_command_or_raise(curl_manifest_command)
  end

  def upload_segment(from_io, segment_name)
    open('|'+full_curl_copy_command('-', segment_name), 'w') do |to_io|
      copy_length = IO.copy_stream(from_io, to_io, @upload_segment_size)
      Syslog.debug("#{self.class.name}: Uploaded #{copy_length} bytes to #{segment_name}")
    end
  end

  def full_curl_copy_command(from_file, to_file=@image_url)
    "curl -f -s -S #{headers} #{@logon} -T #{from_file} #{to_file}"
  end

  def curl_manifest_command
    "curl -f -s -S #{headers} -X PUT -H 'X-Object-Manifest: #{url_path.sub(%r{^/v1/acc-\w{5}/},'')}' #{@image_url} --data-binary ''"
  end

  def zap
    if File.symlink? path
      Syslog.debug("#{self.class.name}: Symlink detected - unlinking #{path}")
      File.delete path
    elsif File.exist? path
      qemu_shred path
    end
  rescue => e
    Syslog.err("#{self.class.name}: Zap error '#{e.message}' for #{@image_url}")
  end

end
