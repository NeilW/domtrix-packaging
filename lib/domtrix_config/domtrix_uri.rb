class DomtrixUri < DelegateClass(URI)

  def initialize(uri, config=nil, headers=nil)
    @headers = headers
    @config = config
    if uri.respond_to?(:headers)
      temp = uri.__getobj__.dup
      @headers ||= uri.headers && uri.headers.dup
    else
      temp = Kernel.URI(uri.to_s)
    end
    super(temp)
    if config && missing_ftp_credentials?
      temp.user = config['ftp_login']
      temp.password = config['ftp_password']
    end
  end

  attr_accessor :headers

  def display_uri_name
    local_uri = __getobj__.dup
    local_uri.user = nil
    local_uri.password = nil
    local_uri.to_s
  end

  def missing_ftp_credentials?
    __getobj__.scheme == 'ftp' && __getobj__.user.nil?
  end

  def basename
    File.basename(__getobj__.path, '.*')
  end

end
