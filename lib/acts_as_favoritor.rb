# frozen_string_literal: true

require 'acts_as_favoritor/version'

module ActsAsFavoritor
  require 'acts_as_favoritor/configuration'

  autoload :Favoritor, 'acts_as_favoritor/favoritor'
  autoload :Favoritable, 'acts_as_favoritor/favoritable'
  autoload :FavoritorLib, 'acts_as_favoritor/favoritor_lib'
  autoload :FavoriteScopes, 'acts_as_favoritor/favorite_scopes'

  require 'acts_as_favoritor/railtie' if defined?(Rails::Railtie)
end
