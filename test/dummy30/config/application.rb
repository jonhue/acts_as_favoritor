# frozen_string_literal: true

require File.expand_path('boot', __dir__)

require 'active_model/railtie'
require 'active_record/railtie'

Bundler.require
require 'acts_as_favoritor'

module Dummy
  class Application < Rails::Application
    config.encoding = 'utf-8'
    config.filter_parameters += [:password]

    config.active_record.sqlite3.represent_boolean_as_integer = true
  end
end
