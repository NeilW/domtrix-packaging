class DomtrixLvmVolume < DomtrixUriBase

  include DomtrixQemuTools

  def create_from(local_file)
    @local_file = local_file
    if stream?(local_file)
      Syslog.debug("#{self.class.name}: Stream detected, copying image")
      FileUtils.cp(local_file, url_path)
    else
      qemu_convert(local_file, url_path)
    end
  rescue => e
    raise error_class, e.message
  end

end

