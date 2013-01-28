module DomtrixConfig

  def source=(config_instance)
    @@config = config_instance
  end

  def config
    @@config
  rescue NameError
    @@config = QueueConfig.instance
  end

end
