require 'acts_as_favoritor/version'

module ActsAsFavoritor

    autoload :Favoritor, 'acts_as_favoritor/favoritor'
    autoload :Favoritable, 'acts_as_favoritor/favoritable'
    autoload :FavoritorLib, 'acts_as_favoritor/favoritor_lib'
    autoload :FavoriteScopes, 'acts_as_favoritor/favorite_scopes'

    def self.setup
        @configuration ||= Configuration.new
        yield @configuration if block_given?
    end

    def self.method_missing method_name, *args, &block
        if method_name == :custom_parent_classes=
            ActiveSupport::Deprecation.warn 'Setting custom parent classes is deprecated and will be removed in future versions.'
        end
        @configuration.respond_to?(method_name) ?
        @configuration.send(method_name, *args, &block) : super
    end

    class Configuration
        attr_accessor :custom_parent_classes

        def initialize
            @custom_parent_classes = []
        end
    end

    setup

    require 'favoritor/railtie' if defined?(Rails) && Rails::VERSION::MAJOR >= 3
    
end
