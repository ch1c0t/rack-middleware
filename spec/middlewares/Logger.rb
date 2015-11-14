def args level = ::Logger::INFO
  @level = level
end

def before
  logger = ::Logger.new @env[Rack::RACK_ERRORS]
  logger.level = @level

  @env[Rack::RACK_LOGGER] = logger
end
