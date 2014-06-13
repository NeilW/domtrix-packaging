module DomtrixQemuTools

  class QemuError < StandardError; end

  def qemu_create(from, to, qcow2_backing_format=true)
    Syslog.debug("#{self.class.name}: Qemu creating #{to} from #{from}")
    qemu_run_command(qemu_create_command(from, to, qcow2_backing_format))
  end

  def qemu_convert(from, to, options=nil)
    Syslog.debug("#{self.class.name}: Qemu converting #{from} into #{to}")
    Syslog.debug("#{self.class.name}: with option #{options}") if options
    qemu_run_command(qemu_convert_command(from, to, options))
  end

  def qemu_rebase(from, to)
    Syslog.debug("#{self.class.name}: Qemu rebasing #{to} onto #{from}")
    qemu_run_command(qemu_rebase_command(from, to))
  end

  def qemu_shred(*files)
    if files.empty?
      Syslog.debug("#{self.class.name}: Nothing to shred")
    else
      Syslog.debug("#{self.class.name}: Shredding files - #{files.inspect}")
      qemu_run_command(qemu_shred_command(*files))
    end
  end

  def qemu_image_info(filename)
    result={}
    `env LC_ALL=C LANG=C qemu-img info #{filename}`.each_line("\n") do |line|
      temp = line.split(':')
      if temp[1] =~ /(\d+) bytes/
        result[temp[0]] = Regexp.last_match(1).to_i
      else
        result[temp[0]] = temp[1].strip
      end
    end
    result
  end

  def qemu_run_command(command)
    o, e, s = Open3.capture3(command)
    if s.success? && e.empty?
      return true
    else
      raise(QemuError, "Failed to create image: #{e}")
    end
  end

  def qemu_create_command(from, to, backing_fmt=true)
    "qemu-img create -f qcow2 -o backing_file=#{from}#{
      if backing_fmt then ',backing_fmt=qcow2' end} #{to}"
  end

  def qemu_convert_command(from, to, options=nil)
    "qemu-img convert #{options} #{from} #{to}"
  end

  def qemu_rebase_command(from, to)
    "qemu-img rebase -b #{from} #{to}"
  end

  def qemu_shred_command(*files)
    "shred -u -n 0 -z #{files.join(' ')}"
  end

  def stream?(filename)
    File.pipe?(filename) || File.chardev?(filename)
  end

end
  
unless Open3.respond_to? :capture3

module Open3

  def capture3(*cmd, &block)
    popen3(*cmd) {|i, o, e|
      i.close
      out_reader =  Thread.new {o.read}
      err_reader =  Thread.new {e.read}
      [out_reader.value, err_reader.value, $?]
    }
  end
  module_function :capture3

end

end
  
