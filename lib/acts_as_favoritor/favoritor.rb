module ActsAsFavoritor #:nodoc:
    module Favoritor

        def self.included base
            base.extend ClassMethods
        end

        module ClassMethods
            def acts_as_favoritor
                has_many :favorites, as: :favoritor, dependent: :destroy
                include ActsAsFavoritor::Favoritor::InstanceMethods
                include ActsAsFavoritor::FavoritorLib
            end
        end

        module InstanceMethods

            # Returns true if this instance has favorited the object passed as an argument.
            def favorited? favoritable, options = {}
                if options.has_key?(:multiple_scopes) == false
                    options[:parameter] = favoritable
                    validate_scopes __method__, options
                elsif options[:multiple_scopes]
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = 0 < Favorite.unblocked.send(scope + '_list').for_favoritor(self).for_favoritable(favoritable).count
                    end
                    return results
                else
                    return 0 < Favorite.unblocked.send(options[:scope] + '_list').for_favoritor(self).for_favoritable(favoritable).count
                end
            end

            # Returns true if this instance has blocked the object passed as an argument.
            def blocked? favoritable, options = {}
                if options.has_key?(:multiple_scopes) == false
                    options[:parameter] = favoritable
                    validate_scopes __method__, options
                elsif options[:multiple_scopes]
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = 0 < Favorite.blocked.send(scope + '_list').for_favoritor(self).for_favoritable(favoritable).count
                    end
                    return results
                else
                    return 0 < Favorite.blocked.send(options[:scope] + '_list').for_favoritor(self).for_favoritable(favoritable).count
                end
            end

            # Returns true if this instance has favorited the object passed as an argument.
            # Returns nil if this instance has not favorited the object passed as an argument.
            # Returns false if this instance has blocked the object passed as an argument.
            def favorited_type favoritable, options = {}
                if options.has_key?(:multiple_scopes) == false
                    options[:parameter] = favoritable
                    validate_scopes __method__, options
                elsif options[:multiple_scopes]
                    results = {}
                    options[:scope].each do |scope|
                        if Favorite.unblocked.send(scope + '_list').for_favoritor(self).for_favoritable(favoritable).count > 0
                            results[scope] = true
                        elsif Favorite.blocked.send(scope + '_list').for_favoritor(self).for_favoritable(favoritable).count > 0
                            results[scope] = false
                        else
                            results[scope] = nil
                        end
                    end
                    return results
                else
                    if Favorite.unblocked.send(options[:scope] + '_list').for_favoritor(self).for_favoritable(favoritable).count > 0
                        return true
                    elsif Favorite.blocked.send(options[:scope] + '_list').for_favoritor(self).for_favoritable(favoritable).count > 0
                        return false
                    else
                        return nil
                    end
                end
            end

            # Returns the number of objects this instance has favorited.
            def favorites_count options = {}
                if options.has_key?(:multiple_scopes) == false
                    validate_scopes __method__, options
                elsif options[:multiple_scopes]
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = Favorite.unblocked.send(scope + '_list').for_favoritor(self).count
                    end
                    return results
                else
                    return Favorite.unblocked.send(options[:scope] + '_list').for_favoritor(self).count
                end
            end

            # Creates a new favorite record for this instance to favorite the passed object.
            # Does not allow duplicate records to be created.
            def favorite favoritable, options = {}
                if options.has_key?(:multiple_scopes) == false
                    options[:parameter] = favoritable
                    validate_scopes __method__, options
                elsif options[:multiple_scopes]
                    results = {}
                    options[:scope].each do |scope|
                        if self != favoritable && scope != 'all'
                            params = {favoritable_id: favoritable.id, favoritable_type: parent_class_name(favoritable), scope: scope}
                            results[scope] = favorites.where(params).first_or_create!
                        end
                    end
                    return results
                else
                    if self != favoritable && options[:scope] != 'all'
                        params = {favoritable_id: favoritable.id, favoritable_type: parent_class_name(favoritable), scope: options[:scope]}
                        return favorites.where(params).first_or_create!
                    end
                end
            end

            # Deletes the favorite record if it exists.
            def remove_favorite favoritable, options = {}
                if options.has_key?(:multiple_scopes) == false
                    options[:parameter] = favoritable
                    validate_scopes __method__, options
                elsif options[:multiple_scopes]
                    results = {}
                    options[:scope].each do |scope|
                        if favorite = get_favorite(favoritable, scope: scope)
                            results[scope] = favorite.destroy
                        end
                    end
                    return results
                else
                    if favorite = get_favorite(favoritable, scope: options[:scope])
                        return favorite.destroy
                    end
                end
            end

            # returns the favorite records to the current instance
            def favorites_scoped options = {}
                if options.has_key?(:multiple_scopes) == false
                    validate_scopes __method__, options
                elsif options[:multiple_scopes]
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = favorites.unblocked.send(scope + '_list').includes :favoritable
                    end
                    return results
                else
                    return favorites.unblocked.send(options[:scope] + '_list').includes :favoritable
                end
            end

            # Returns the favorite records related to this instance by type.
            def favorites_by_type favoritable_type, options = {}
                if options.has_key?(:multiple_scopes) == false
                    options[:parameter] = favoritable_type
                    validate_scopes __method__, options
                elsif options[:multiple_scopes]
                    results = {}
                    options[:scope].each do |scope|
                        favorites_scope = favorites_scoped(scope: scope).for_favoritable_type favoritable_type
                        results[scope] = favorites_scope = apply_options_to_scope favorites_scope, options
                    end
                    return results
                else
                    favorites_scope = favorites_scoped(scope: options[:scope]).for_favoritable_type favoritable_type
                    return favorites_scope = apply_options_to_scope(favorites_scope, options)
                end
            end

            # Returns the favorite records related to this instance with the favoritable included.
            def all_favorites options = {}
                if options.has_key?(:multiple_scopes) == false
                    validate_scopes __method__, options
                elsif options[:multiple_scopes]
                    results = {}
                    options[:scope].each do |scope|
                        favorites_scope = favorites_scoped scope: scope
                        results[scope] = favorites_scope = apply_options_to_scope favorites_scope, options
                    end
                    return results
                else
                    favorites_scope = favorites_scoped scope: options[:scope]
                    return favorites_scope = apply_options_to_scope(favorites_scope, options)
                end
            end

            # Returns the actual records which this instance has favorited.
            def all_favorited options = {}
                if options.has_key?(:multiple_scopes) == false
                    validate_scopes __method__, options
                elsif options[:multiple_scopes]
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = all_favorites(options).collect{ |f| f.favoritable }
                    end
                    return results
                else
                    return all_favorites(options).collect{ |f| f.favoritable }
                end
            end

            # Returns the actual records of a particular type which this record has fovarited.
            def favorited_by_type favoritable_type, options = {}
                if options.has_key?(:multiple_scopes) == false
                    options[:parameter] = favoritable_type
                    validate_scopes __method__, options
                elsif options[:multiple_scopes]
                    results = {}
                    options[:scope].each do |scope|
                        favoritables = favoritable_type.constantize.joins(:favorited).where('favorites.blocked': false,
                            'favorites.favoritor_id': id,
                            'favorites.favoritor_type': parent_class_name(self),
                            'favorites.favoritable_type': favoritable_type,
                            'favorites.scope': scope)
                        if options.has_key? :limit
                            favoritables = favoritables.limit options[:limit]
                        end
                        if options.has_key? :includes
                            favoritables = favoritables.includes options[:includes]
                        end
                        results[scope] = favoritables
                    end
                    return results
                else
                    favoritables = favoritable_type.constantize.joins(:favorited).where('favorites.blocked': false,
                        'favorites.favoritor_id': id,
                        'favorites.favoritor_type': parent_class_name(self),
                        'favorites.favoritable_type': favoritable_type,
                        'favorites.scope': options[:scope])
                    if options.has_key? :limit
                        favoritables = favoritables.limit options[:limit]
                    end
                    if options.has_key? :includes
                        favoritables = favoritables.includes options[:includes]
                    end
                    return favoritables
                end
            end

            def favorited_by_type_count favoritable_type, options = {}
                if options.has_key?(:multiple_scopes) == false
                    options[:parameter] = favoritable_type
                    validate_scopes __method__, options
                elsif options[:multiple_scopes]
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = favorites.unblocked.send(scope + '_list').for_favoritable_type(favoritable_type).count
                    end
                    return results
                else
                    return favorites.unblocked.send(options[:scope] + '_list').for_favoritable_type(favoritable_type).count
                end
            end

            # Allows magic names on favorited_by_type
            # e.g. favorited_users == favorited_by_type 'User'
            # Allows magic names on favorited_by_type_count
            # e.g. favorited_users_count == favorited_by_type_count 'User'
            def method_missing m, *args
                if m.to_s[/favorited_(.+)_count/]
                    favorited_by_type_count $1.singularize.classify
                elsif m.to_s[/favorited_(.+)/]
                    favorited_by_type $1.singularize.classify
                else
                    super
                end
            end

            def respond_to? m, include_private = false
                super || m.to_s[/favorited_(.+)_count/] || m.to_s[/favorited_(.+)/]
            end

            # Returns a favorite record for the current instance and favoritable object.
            def get_favorite favoritable, options = {}
                if options.has_key?(:multiple_scopes) == false
                    options[:parameter] = favoritable
                    validate_scopes __method__, options
                elsif options[:multiple_scopes]
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = favorites.unblocked.send(scope + '_list').for_favoritable(favoritable).first
                    end
                    return results
                else
                    return favorites.unblocked.send(options[:scope] + '_list').for_favoritable(favoritable).first
                end
            end

            def blocks options = {}
                if options.has_key?(:multiple_scopes) == false
                    validate_scopes __method__, options
                elsif options[:multiple_scopes]
                    results = {}
                    options[:scope].each do |scope|
                        blocked_favoritors_scope = favoritables_scoped(scope: scope).blocked
                        blocked_favoritors_scope = apply_options_to_scope blocked_favoritors_scope, options
                        results[scope] = blocked_favoritors_scope.to_a.collect{ |f| f.favoritable }
                    end
                    return results
                else
                    blocked_favoritors_scope = favoritors_scoped(scope: options[:scope]).blocked
                    blocked_favoritors_scope = apply_options_to_scope blocked_favoritors_scope, options
                    return blocked_favoritors_scope.to_a.collect{ |f| f.favoritable }
                end
            end

            def block favoritable, options = {}
                if options.has_key?(:multiple_scopes) == false
                    options[:parameter] = favoritable
                    validate_scopes __method__, options
                elsif options[:multiple_scopes]
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = get_favorite(favoritable, scope: scope) ? block_existing_favorite(favoritable, scope: scope) : block_future_favorite(favoritable, scope: scope)
                    end
                    return results
                else
                    return get_favorite(favoritable, scope: options[:scope]) ? block_existing_favorite(favoritable, scope: options[:scope]) : block_future_favorite(favoritable, scope: options[:scope])
                end
            end

            def unblock favoritable, options = {}
                if options.has_key?(:multiple_scopes) == false
                    options[:parameter] = favoritable
                    validate_scopes __method__, options
                elsif options[:multiple_scopes]
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = get_favorite(favoritable, scope: scope)&.update_attribute :blocked, false
                    end
                    return results
                else
                    return get_favorite(favoritable, scope: options[:scope])&.update_attribute :blocked, false
                end
            end

            def blocked_favoritables_count options = {}
                if options.has_key?(:multiple_scopes) == false
                    validate_scopes __method__, options
                elsif options[:multiple_scopes]
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = favorites.blocked.send(scope + '_list').count
                    end
                    return results
                else
                    return favorites.blocked.send(options[:scope] + '_list').count
                end
            end

            private

            def block_future_favorite favoritable, options = {}
                if options.has_key?(:multiple_scopes) == false
                    options[:parameter] = favoritable
                    validate_scopes __method__, options
                elsif options[:multiple_scopes]
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = Favorite.create favoritable: favoritable, favoritor: self, blocked: true, scope: scope
                    end
                    return results
                else
                    return Favorite.create favoritable: favoritable, favoritor: self, blocked: true, scope: options[:scope]
                end
            end

            def block_existing_favorite favoritable, options = {}
                if options.has_key?(:multiple_scopes) == false
                    options[:parameter] = favoritable
                    validate_scopes __method__, options
                elsif options[:multiple_scopes]
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = get_favorite(favoritable, scope: scope).block!
                    end
                    return results
                else
                    return get_favorite(favoritable, scope: options[:scope]).block!
                end
            end

        end

    end
end
