module ActsAsFavoritor #:nodoc:
    module Favoritable

        def self.included base
            base.extend ClassMethods
        end

        module ClassMethods
            def acts_as_favoritable
                has_many :favorited, as: :favoritable, dependent: :destroy, class_name: 'Favorite'
                include ActsAsFavoritor::Favoritable::InstanceMethods
                include ActsAsFavoritor::FavoritorLib
            end
        end

        module InstanceMethods

            # Returns the number of favoritors a record has.
            def favoritors_count options = {}
                if options.has_key?(:multiple_scopes) == false
                    results = validate_scopes __method__, options
                elsif options.has_key?(:multiple_scopes) && options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = favorited.unblocked.send(scope + '_list').count
                    end
                else
                    results = favorited.unblocked.send(options[:scope] + '_list').count
                end
                results
            end

            # Returns the favoritors by a given type
            def favoritors_by_type favoritor_type, options = {}
                options[:favoritor_type] = favoritor_type
                if options.has_key?(:multiple_scopes) == false
                    results = validate_scopes __method__, options
                elsif options.has_key?(:multiple_scopes) && options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        favorites = options[:favoritor_type].constantize.joins(:favorites).where('favorites.blocked': false,
                            'favorites.favoritable_id': id,
                            'favorites.favoritable_type': parent_class_name(self),
                            'favorites.favoritor_type': options[:favoritor_type],
                            'favorites.scope': scope)
                        if options.has_key? :limit
                            favorites = favorites.limit options[:limit]
                        end
                        if options.has_key? :includes
                            favorites = favorites.includes options[:includes]
                        end
                        results[scope] = favorites
                    end
                else
                    favorites = options[:favoritor_type].constantize.joins(:favorites).where('favorites.blocked': false,
                        'favorites.favoritable_id': id,
                        'favorites.favoritable_type': parent_class_name(self),
                        'favorites.favoritor_type': options[:favoritor_type],
                        'favorites.scope': options[:scope])
                    if options.has_key? :limit
                        favorites = favorites.limit options[:limit]
                    end
                    if options.has_key? :includes
                        favorites = favorites.includes options[:includes]
                    end
                    results = favorites
                end
                results
            end

            def favoritors_by_type_count favoritor_type, options = {}
                options[:favoritor_type] = favoritor_type
                if options.has_key?(:multiple_scopes) == false
                    results = validate_scopes __method__, options
                elsif options.has_key?(:multiple_scopes) && options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = favorited.unblocked.send(scope + '_list').for_favoritor_type(options[:favoritor_type]).count
                    end
                else
                    results = favorited.unblocked.send(options[:scope] + '_list').for_favoritor_type(options[:favoritor_type]).count
                end
                results
            end

            # Allows magic names on favoritors_by_type
            # e.g. user_favoritors == favoritors_by_type 'User'
            # Allows magic names on favoritors_by_type_count
            # e.g. count_user_favoritors == favoritors_by_type_count 'User'
            def method_missing m, *args
                if m.to_s[/count_(.+)_favoritors/]
                    favoritors_by_type_count $1.singularize.classify
                elsif m.to_s[/(.+)_favoritors/]
                    favoritors_by_type $1.singularize.classify
                else
                    super
                end
            end

            def respond_to? m, include_private = false
                super || m.to_s[/count_(.+)_favoritors/] || m.to_s[/(.+)_favoritors/]
            end

            def blocked_favoritors_count options = {}
                if options.has_key?(:multiple_scopes) == false
                    results = validate_scopes __method__, options
                elsif options.has_key?(:multiple_scopes) && options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = favorited.blocked.send(scope + '_list').count
                    end
                else
                    results = favorited.blocked.send(options[:scope] + '_list').count
                end
                results
            end

            # Returns the favorited records scoped
            def favoritors_scoped options = {}
                if options.has_key?(:multiple_scopes) == false
                    results = validate_scopes __method__, options
                elsif options.has_key?(:multiple_scopes) && options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = favorited.send(scope + '_list').includes :favoritor
                    end
                else
                    results = favorited.send(options[:scope] + '_list').includes :favoritor
                end
                results
            end

            def favoritors options = {}
                if options.has_key?(:multiple_scopes) == false
                    results = validate_scopes __method__, options
                elsif options.has_key?(:multiple_scopes) && options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        favoritors_scope = favoritors_scoped(scope).unblocked
                        favoritors_scope = apply_options_to_scope favoritors_scope, options
                        results[scope] = favoritors_scope.to_a.collect{ |f| f.favoritor }
                    end
                else
                    favoritors_scope = favoritors_scoped(options[:scope]).unblocked
                    favoritors_scope = apply_options_to_scope favoritors_scope, options
                    results = favoritors_scope.to_a.collect{ |f| f.favoritor }
                end
                results
            end

            def blocks options = {}
                if options.has_key?(:multiple_scopes) == false
                    results = validate_scopes __method__, options
                elsif options.has_key?(:multiple_scopes) && options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        blocked_favoritors_scope = favoritors_scoped(scope).blocked
                        blocked_favoritors_scope = apply_options_to_scope blocked_favoritors_scope, options
                        results[scope] = blocked_favoritors_scope.to_a.collect{ |f| f.favoritor }
                    end
                else
                    blocked_favoritors_scope = favoritors_scoped(options[:scope]).blocked
                    blocked_favoritors_scope = apply_options_to_scope blocked_favoritors_scope, options
                    results = blocked_favoritors_scope.to_a.collect{ |f| f.favoritor }
                end
                results
            end

            # Returns true if the current instance is favorited by the passed record
            # Returns false if the current instance is blocked by the passed record or no favorite is found
            def favorited_by? favoritor, options = {}
                options[:favoritor] = favoritor
                if options.has_key?(:multiple_scopes) == false
                    results = validate_scopes __method__, options
                elsif options.has_key?(:multiple_scopes) && options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = favorited.unblocked.send(scope + '_list').for_favoritor(options[:favoritor]).first.present?
                    end
                else
                    results = favorited.unblocked.send(options[:scope] + '_list').for_favoritor(options[:favoritor]).first.present?
                end
                results
            end

            def block favoritor, options = {}
                options[:favoritor] = favoritor
                if options.has_key?(:multiple_scopes) == false
                    results = validate_scopes __method__, options
                elsif options.has_key?(:multiple_scopes) && options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = get_favorite_for(options[:favoritor], scope: scope) ? block_existing_favorite(options[:favoritor], scope: scope) : block_future_favorite(options[:favoritor], scope: scope)
                    end
                else
                    results = get_favorite_for(options[:favoritor], scope: options[:scope]) ? block_existing_favorite(options[:favoritor], scope: options[:scope]) : block_future_favorite(options[:favoritor], scope: options[:scope])
                end
                results
            end

            def unblock favoritor, options = {}
                options[:favoritor] = favoritor
                if options.has_key?(:multiple_scopes) == false
                    results = validate_scopes __method__, options
                elsif options.has_key?(:multiple_scopes) && options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = get_favorite_for(options[:favoritor], scope: scope).update_attribute :blocked, false
                    end
                else
                    results = get_favorite_for(options[:favoritor], scope: options[:scope]).update_attribute :blocked, false
                end
                results
            end

            def get_favorite_for favoritor, options = {}
                options[:favoritor] = favoritor
                if options.has_key?(:multiple_scopes) == false
                    results = validate_scopes __method__, options
                elsif options.has_key?(:multiple_scopes) && options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = favorited.send(scope + '_list').for_favoritor(options[:favoritor]).first
                    end
                else
                    results = favorited.send(options[:scope] + '_list').for_favoritor(options[:favoritor]).first
                end
                results
            end

            private

            def block_future_favorite favoritor, options = {}
                options[:favoritor] = favoritor
                if options.has_key?(:multiple_scopes) == false
                    results = validate_scopes __method__, options
                elsif options.has_key?(:multiple_scopes) && options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = Favorite.create favoritable: self, favoritor: options[:favoritor], blocked: true, scope: scope
                    end
                else
                    results = Favorite.create favoritable: self, favoritor: options[:favoritor], blocked: true, scope: options[:scope]
                end
                results
            end

            def block_existing_favorite favoritor, options = {}
                options[:favoritor] = favoritor
                if options.has_key?(:multiple_scopes) == false
                    results = validate_scopes __method__, options
                elsif options.has_key?(:multiple_scopes) && options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = get_favorite_for(options[:favoritor], scope: scope).block!
                    end
                else
                    results = get_favorite_for(options[:favoritor], scope: options[:scope]).block!
                end
                results
            end

        end

    end
end
