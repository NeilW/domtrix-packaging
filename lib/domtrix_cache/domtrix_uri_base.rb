class DomtrixUriBase

  def initialize(url)
    Syslog.debug("#{self.class.name}: initialising")
    if url.kind_of? String
      @image_url = URI.parse url
    else
      @image_url = url
    end
    @logon = "-u #{@image_url.userinfo}" if @image_url.userinfo && !@image_url.userinfo.empty?
    @image_url.user = nil
    @image_url.password = nil
    Syslog.debug("#{self.class.name}: initialised")
  end

  def url_path
    @image_url.path
  end

  def basename
    @basename ||= File.basename(url_path, '.*')
  end

  def error_class
    @error_class ||= get_error_class
  end

private

  #Dynamically create the error class from the running class name.
  def get_error_class
    name = (self.class.name+'Error').to_sym
    Object.const_get name
  rescue
    Object.const_set(name, Class.new(StandardError))
  end

  def run_curl_command(curl_command=curl_copy_command)
    Syslog.debug("#{self.class.name}: #{curl_command}")
    system('bash', '-c', 'set -o pipefail;'+curl_command)
    @curl_error = $?.exitstatus.to_s
    $?.success?
  end

end

