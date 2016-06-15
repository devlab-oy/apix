module Apix
  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  class Configuration
    attr_accessor :ver, :soft, :transfer_id, :transfer_key, :url

    def initialize
      @url = "test-api.apix.fi"
      @soft = nil
      @ver = nil
      @transfer_id = nil
      @transfer_key = nil
    end
  end
end
