module DomtrixQcowVolumeNames
  
  def backing_file
    @backing_file ||= url_path+'_back'
  end

  def snap_file
    @snap_file ||= url_path+'_snap'
  end

  def alt_url_path
    @alt_url_path ||= url_path + '_alt'
  end

  def current_path
    if File.exist?(alt_url_path)
      return nil if File.exist?(url_path)
      return alt_url_path
    else
      return url_path
    end
  end

  def alternate_path
    temp_current_path = current_path
    temp_current_path && (temp_current_path == url_path ? alt_url_path : url_path)
  end
  
end
  
  
