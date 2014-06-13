class DomtrixFileImage < DomtrixUriBase

  include CommandRunner

  def obtain_local_file
    case File.extname(url_path)
    when '.gz'
      sparse_expand('gzip')
      local_file = target
    when '.bz2'
      sparse_expand('bzip2')
      local_file = target
    when '.xz', '.lzma'
      sparse_expand('xz')
      local_file = target
    else
      local_file = url_path
    end
    yield local_file
  rescue => e
    raise error_class, e.message
  end

  def target
    File.join(File.dirname(url_path), basename)
  end

  def sparse_expand(expander)
    command = "#{expander} -dc #{url_path} | cp --sparse=always /dev/stdin #{target}"
    Syslog.debug("Expanding image at #{url_path}")
    Syslog.debug(command)
    run(
      command,
      "expand #{url_path} with #{expander}",
      "Failed to expand #{url_path} with #{expander}"
    )
    FileUtils.rm_f url_path
  end

end
