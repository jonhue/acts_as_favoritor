module ActsAsFavoritor

    def self.default_scope
        config = get_config
        if config.key(:default_scope)
            config[:default_scope]
        else
            'favorite'
        end
    end


    private


    def self.get_config
        require 'yaml'

        begin
            YAML.load_file('config/acts_as_favoritor.yml')
        rescue Exception
            warn 'WARNING (acts_as_favoritor): You need to run `rails g acts_as_favoritor` first.'
            exit
        end
    end

end
