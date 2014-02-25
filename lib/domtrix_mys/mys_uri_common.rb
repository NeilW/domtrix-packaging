#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2013, Neil Wilson, Brightbox Systems
#
#  MySQL common uri commands

module MysUriCommon

  def data_uri
    @data[:uri]
  end

  def data_area
    "/var/lib/mysql"
  end

  #Change this to select the tar compression protocol to use
  def compression_tag
    ""
  end

  def dot_dirs
    %w[. ..].collect! {|x| File.join(data_area, x) }
  end

  def data_area_file_list
    Dir.glob(File.join(data_area, '*'), File::FNM_DOTMATCH) - dot_dirs
  end

  def cache_dir?(d)
    filename=File.join(d, 'CACHEDIR.TAG')
    File.file?(filename) &&
      File.read(filename, 43) == 'Signature: 8a477f597d28d172789f06886806bc55'
  end

  def data_area_cachedirs
    data_area_file_list.find_all { |d| cache_dir?(d) }
  end

  def data_area_normal_files
    data_area_file_list.reject { |d| cache_dir?(d) }
  end

  def target_uri_name
    @targeturi ||= URI(data_uri)
    add_ftp_credentials(@targeturi) if missing_ftp_credentials?(@targeturi)
    @targeturi
  rescue URI::InvalidURIError
    raise "Invalid URI: #{target_uri_display_name}"
  end

  def target_uri_display_name
    if @targeturi
      strip_credentials(@targeturi) 
    else
      data_uri
    end
  end

  def required_elements_present?
    target_uri_name
  end

  def strip_credentials(uri_ref)
    local_uri = uri_ref.dup
    local_uri.user = nil
    local_uri.password = nil
    local_uri.to_s
  end

  def missing_ftp_credentials?(uri_name)
    uri_name.scheme == 'ftp' && uri_name.user.nil?
  end

  def add_ftp_credentials(uri_name)
    uri_name.user = config['ftp_login']
    uri_name.password = config['ftp_password']
  end

end
