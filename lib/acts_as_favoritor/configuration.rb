# frozen_string_literal: true

module ActsAsFavoritor
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield configuration
  end

  class Configuration
    DEFAULT_SCOPE = :favorite
    DEFAULT_CACHE = false

    attr_accessor :cache, :default_scope

    def initialize
      @default_scope = DEFAULT_SCOPE
      @cache         = DEFAULT_CACHE
    end
  end
end
