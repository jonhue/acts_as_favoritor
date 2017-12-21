module ActsAsFavoritor
    class Configuration

        attr_accessor :default_scope
        attr_accessor :cache

        def initialize
            @default_scope = 'favorite'
            @cache = false
        end

    end
end
