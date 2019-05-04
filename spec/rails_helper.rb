# frozen_string_literal: true

require 'rails/all'

require 'factory_bot'
require 'rspec/rails'

ENV['RAILS_ENV'] = 'test'
require 'support/rails_app/config/environment'

ActiveRecord::Migration.maintain_test_schema!
ActiveRecord::Schema.verbose = false
load 'support/rails_app/db/schema.rb'

require 'spec_helper'

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.before :suite do
    FactoryBot.find_definitions
  end
end
