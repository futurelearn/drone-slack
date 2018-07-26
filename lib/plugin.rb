class Plugin
  def webhook
    set_parameter("webhook")
  end

  def channel
    set_parameter("channel")
  end

  private

  def set_parameter(parameter_name, required = true)
    parameter = "PLUGIN_" + parameter_name.upcase

    if required && ENV[parameter].nil?
      abort("Must set #{parameter}")
    end

    return false if ENV[parameter].nil?

    ENV[parameter]
  end
end
