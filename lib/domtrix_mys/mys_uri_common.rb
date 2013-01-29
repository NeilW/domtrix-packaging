#!/usr/bin/env ruby
#    Brightbox - Command processor classes
#    Copyright (C) 2013, Neil Wilson, Brightbox Systems
#
#  MySQL common uri commands

module MysUriCommon

  def data_uri
    @data[:uri]
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
