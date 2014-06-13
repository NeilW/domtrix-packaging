class DomtrixFileVolume < DomtrixLvmVolume

  def create_from(local_file)
    Syslog.debug("#{self.class.name}: Checking file access permissions")
    File.open(local_file) {}
    @local_file = local_file
    Syslog.debug("#{self.class.name}: Checking local_file format")
    case
    when stream?(local_file)
      Syslog.debug("#{self.class.name}: Stream detected, copying image")
      copy_image
    when correct_format?
      Syslog.debug("#{self.class.name}: Qcow2 format detected, moving image")
      move_image
    else
      Syslog.debug("#{self.class.name}: Converting local_file from detected "+
        incoming_image_info['file format'] + " format")
      super
    end
  end

  def correct_format?
    incoming_image_info['file format'] == 'qcow2' || zero_image?
  end

  def zero_image?
    incoming_image_info['file format'] == 'raw' &&
      incoming_image_info['virtual size'] == 0
  end

  def incoming_image_info
    @incoming_image_info ||= qemu_image_info(@local_file)
  end

  def move_image
    FileUtils.mv(@local_file, url_path)
  rescue => e
    raise error_class, e.message
  end

  def copy_image
    FileUtils.cp(@local_file, url_path)
  rescue => e
    raise error_class, e.message
  end

end
