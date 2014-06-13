class DomtrixQcowVolume < DomtrixUriBase

  include DomtrixQemuTools
  include DomtrixQcowVolumeNames
  
  def create_from(local_file)
    File.open(local_file) {}
    clean_destination
    if stream?(local_file)
      FileUtils.cp(local_file, backing_file)
    else
      File.link local_file, backing_file
    end
    create_volumes
  rescue => e
    raise error_class, e.message
  end

  def create_volumes
    qemu_create(backing_file, snap_file, false)
    qemu_create(snap_file, url_path)
  rescue
    clean_destination
    raise
  end

  def clean_destination
    FileUtils.rm_f backing_file
    qemu_shred(*(Dir[url_path+'*']))
  end

end
