require File.expand_path '../boot', __FILE__

require 'active_model/railtie'
require 'active_record/railtie'

Bundler.require
require 'acts_as_favoritor'

module Dummy
    class Application < Rails::Application
        config.encoding = 'utf-8'
        config.filter_parameters += [:password]
    end
end
