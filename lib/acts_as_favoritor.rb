require 'acts_as_favoritor/version'

module ActsAsFavoritor

    autoload :Configuration, 'acts_as_favoritor/configuration'

    class << self
        attr_accessor :configuration
    end

    def self.configure
        self.configuration ||= Configuration.new
        yield configuration
    end

    autoload :Favoritor, 'acts_as_favoritor/favoritor'
    autoload :Favoritable, 'acts_as_favoritor/favoritable'
    autoload :FavoritorLib, 'acts_as_favoritor/favoritor_lib'
    autoload :FavoriteScopes, 'acts_as_favoritor/favorite_scopes'

    require 'acts_as_favoritor/railtie' if defined?(Rails)

end
