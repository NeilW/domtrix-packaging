require 'optparse'
require 'syslog'

module DomtrixAuthToken

module_function

  def bad_usage(args)
    Syslog.err(usage(args)) if Syslog.opened?
    abort usage(args)
  end

  def usage(args)
    "Usage: #{File.basename $PROGRAM_NAME} [options] #{args}"
  end

  def options(banner = nil)
    options = {}
    OptionParser.new do |o|
      o.banner = usage(banner) if banner
      o.on('-a', '--auth AUTH_TOKEN',
	'Use AUTH_TOKEN for non-local requests') do |token|
	  options['auth_token'] = token
      end
      o.on_tail('-h', 'Print this help message') { puts o; exit }
      o.parse!
    end
    options
  end

end
    
