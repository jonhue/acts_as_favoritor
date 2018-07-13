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
    attr_accessor :default_scope
    attr_accessor :cache

    def initialize
      @default_scope = 'favorite'
      @cache = false
    end
  end
end
