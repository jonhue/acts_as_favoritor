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
                elsif options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = 0 < Favorite.unblocked.send(scope + '_list').for_favoritor(self).for_favoritable(favoritable).count
                    end
                    results
                else
                    0 < Favorite.unblocked.send(options[:scope] + '_list').for_favoritor(self).for_favoritable(favoritable).count
                end
            end

            # Returns the number of objects this instance has favorited.
            def favorites_count options = {}
                if options.has_key?(:multiple_scopes) == false
                    validate_scopes __method__, options
                elsif options[:multiple_scopes] == true
                    raise options.to_s
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = Favorite.unblocked.send(scope + '_list').for_favoritor(self).count
                    end
                    results
                else
                    Favorite.unblocked.send(options[:scope] + '_list').for_favoritor(self).count
                end
            end

            # Creates a new favorite record for this instance to favorite the passed object.
            # Does not allow duplicate records to be created.
            def favorite favoritable, options = {}
                if options.has_key?(:multiple_scopes) == false
                    options[:parameter] = favoritable
                    validate_scopes __method__, options
                elsif options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        if self != favoritable && scope != 'all'
                            params = {favoritable_id: favoritable.id, favoritable_type: parent_class_name(favoritable), scope: scope}
                            results[scope] = favorites.where(params).first_or_create!
                        end
                    end
                    results
                else
                    if self != favoritable && options[:scope] != 'all'
                        params = {favoritable_id: favoritable.id, favoritable_type: parent_class_name(favoritable), scope: options[:scope]}
                        favorites.where(params).first_or_create!
                    end
                end
            end

            # Deletes the favorite record if it exists.
            def remove_favorite favoritable, options = {}
                if options.has_key?(:multiple_scopes) == false
                    options[:parameter] = favoritable
                    validate_scopes __method__, options
                elsif options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        if favorite = get_favorite(favoritable).send(scope + '_list')
                            results[scope] = favorite.destroy
                        end
                    end
                    results
                else
                    if favorite = get_favorite(favoritable).send(options[:scope] + '_list')
                        favorite.destroy
                    end
                end
            end

            # returns the favorite records to the current instance
            def favorites_scoped options = {}
                if options.has_key?(:multiple_scopes) == false
                    validate_scopes __method__, options
                elsif options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = favorites.unblocked.send(scope + '_list').includes :favoritable
                    end
                    results
                else
                    favorites.unblocked.send(options[:scope] + '_list').includes :favoritable
                end
            end

            # Returns the favorite records related to this instance by type.
            def favorites_by_type favoritable_type, options = {}
                if options.has_key?(:multiple_scopes) == false
                    options[:parameter] = favoritable_type
                    validate_scopes __method__, options
                elsif options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        favorites_scope = favorites_scoped(scope).for_favoritable_type favoritable_type
                        results[scope] = favorites_scope = apply_options_to_scope favorites_scope, options
                    end
                    results
                else
                    favorites_scope = favorites_scoped(options[:scope]).for_favoritable_type favoritable_type
                    favorites_scope = apply_options_to_scope favorites_scope, options
                end
            end

            # Returns the favorite records related to this instance with the favoritable included.
            def all_favorites options = {}
                if options.has_key?(:multiple_scopes) == false
                    validate_scopes __method__, options
                elsif options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        favorites_scope = favorites_scoped scope
                        results[scope] = favorites_scope = apply_options_to_scope favorites_scope, options
                    end
                    results
                else
                    favorites_scope = favorites_scoped options[:scope]
                    favorites_scope = apply_options_to_scope favorites_scope, options
                end
            end

            # Returns the actual records which this instance has favorited.
            def all_favorited options = {}
                all_favorites(options).collect{ |f| f.favoritable }
            end

            # Returns the actual records of a particular type which this record has fovarited.
            def favorited_by_type favoritable_type, options = {}
                if options.has_key?(:multiple_scopes) == false
                    options[:parameter] = favoritable_type
                    validate_scopes __method__, options
                elsif options[:multiple_scopes] == true
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
                    results
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
                    favoritables
                end
            end

            def favorited_by_type_count favoritable_type, options = {}
                if options.has_key?(:multiple_scopes) == false
                    options[:parameter] = favoritable_type
                    validate_scopes __method__, options
                elsif options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = favorites.unblocked.send(scope + '_list').for_favoritable_type(favoritable_type).count
                    end
                    results
                else
                    favorites.unblocked.send(options[:scope] + '_list').for_favoritable_type(favoritable_type).count
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
                elsif options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = favorites.unblocked.send(scope + '_list').for_favoritable(favoritable).first
                    end
                    results
                else
                    favorites.unblocked.send(options[:scope] + '_list').for_favoritable(favoritable).first
                end
            end

        end

    end
end
