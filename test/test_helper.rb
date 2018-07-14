# frozen_string_literal: true

# Configure Rails Envinronment
ENV['RAILS_ENV'] = 'test'

require File.expand_path('dummy30/config/environment.rb', __dir__)
require 'rails/test_help'

ActiveRecord::Base.logger = Logger.new File.dirname(__FILE__) + '/debug.log'
ActiveRecord::Migration.verbose = false

load File.dirname(__FILE__) + '/schema.rb'

require File.dirname(__FILE__) + '/../lib/generators/templates/model.rb'

require 'shoulda'
require 'shoulda_create'
require 'factory_bot'
ActiveSupport::TestCase.extend ShouldaCreate
FactoryBot.find_definitions
