# frozen_string_literal: true

require 'rails/railtie'

module ActsAsFavoritor
  class Railtie < Rails::Railtie
    initializer 'acts_as_favoritor.active_record' do
      ActiveSupport.on_load :active_record do
        include ActsAsFavoritor::Favoritor
        include ActsAsFavoritor::Favoritable
      end
    end
  end
end
