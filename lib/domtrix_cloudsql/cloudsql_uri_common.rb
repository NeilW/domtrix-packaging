#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2013, Neil Wilson, Brightbox Systems
#
#  MySQL common uri commands

module CloudsqlUriCommon

  def data_uri
    @data[:uri]
  end

  def auth_token
    @data[:auth_token]
  end

  def curl_token_option
    token = current_token
    "-H 'X-Auth-Token:#{token}'" if token
  end

  def mysql_data_area
    "/var/lib/mysql"
  end

  def mysql_service_name
    "mysql"
  end

  def mysql_volgroup
    "mysql"
  end

  def postgres_data_area
    "/var/lib/postgresql"
  end

  def postgres_service_name
    "postgresql"
  end

  def postgres_volgroup
    "pg"
  end

  def headers
    {'auth_token' => auth_token }
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
    @targeturi ||= DomtrixUri.new(data_uri, config, headers)
  rescue URI::InvalidURIError
    raise "Invalid URI: #{target_uri_display_name}"
  end

  def image_identifier
    @data[:resource] || data_uri[-9,9].to_s
  end

  def current_token
    target_uri_name.headers && target_uri_name.headers['auth_token']
  end

  def target_uri_display_name
    if @targeturi
      @targeturi.display_uri_name
    else
      data_uri
    end
  end

  def required_elements_present?
    target_uri_name
  end

end
