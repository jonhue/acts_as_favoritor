module ActsAsFavoritor

    def self.default_scope
        config = get_config
        if config&.key :default_scope
            config[:default_scope]
        else
            'favorite'
        end
    end

    def self.cache
        config = get_config
        if config&.key :cache
            config[:cache]
        else
            false
        end
    end


    private


    def self.get_config
        require 'yaml'

        begin
            YAML.load_file 'config/acts_as_favoritor.yml'
        rescue Exception
        end
    end

end
