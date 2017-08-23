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
                    results = validate_scopes __method__, options
                elsif options.has_key?(:multiple_scopes) && options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = 0 < Favorite.unblocked.send(scope + '_list').for_favoritor(self).for_favoritable(favoritable).count
                    end
                else
                    results = 0 < Favorite.unblocked.send(options[:scope] + '_list').for_favoritor(self).for_favoritable(favoritable).count
                end
                results
            end

            # Returns the number of objects this instance has favorited.
            def favorites_count options = {}
                if options.has_key?(:multiple_scopes) == false
                    results = validate_scopes __method__, options
                elsif options.has_key?(:multiple_scopes) && options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = Favorite.unblocked.send(scope + '_list').for_favoritor(self).count
                    end
                else
                    results = Favorite.unblocked.send(options[:scope] + '_list').for_favoritor(self).count
                end
                results
            end

            # Creates a new favorite record for this instance to favorite the passed object.
            # Does not allow duplicate records to be created.
            def favorite favoritable, options = {}
                if options.has_key?(:multiple_scopes) == false
                    options[:parameter] = favoritable
                    results = validate_scopes __method__, options
                elsif options.has_key?(:multiple_scopes) && options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        if self != favoritable && scope != 'all'
                            params = {favoritable_id: favoritable.id, favoritable_type: parent_class_name(favoritable), scope: scope}
                            results[scope] = favorites.where(params).first_or_create!
                        end
                    end
                else
                    if self != favoritable && options[:scope] != 'all'
                        params = {favoritable_id: favoritable.id, favoritable_type: parent_class_name(favoritable), scope: options[:scope]}
                        results = favorites.where(params).first_or_create!
                    end
                end
                results
            end

            # Deletes the favorite record if it exists.
            def remove_favorite favoritable, options = {}
                if options.has_key?(:multiple_scopes) == false
                    options[:parameter] = favoritable
                    results = validate_scopes __method__, options
                elsif options.has_key?(:multiple_scopes) && options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        if favorite = get_favoritor(favoritable).send(scope + '_list')
                            results[scope] = favorite.destroy
                        end
                    end
                else
                    if favorite = get_favoritor(favoritable).send(options[:scope] + '_list')
                        results = favorite.destroy
                    end
                end
                results
            end

            # returns the favorite records to the current instance
            def favorites_scoped options = {}
                if options.has_key?(:multiple_scopes) == false
                    results = validate_scopes __method__, options
                elsif options.has_key?(:multiple_scopes) && options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = favorites.unblocked.send(scope + '_list').includes :favoritable
                    end
                else
                    results = favorites.unblocked.send(options[:scope] + '_list').includes :favoritable
                end
                results
            end

            # Returns the favorite records related to this instance by type.
            def favorites_by_type favoritable_type, options = {}
                if options.has_key?(:multiple_scopes) == false
                    options[:parameter] = favoritable_type
                    results = validate_scopes __method__, options
                elsif options.has_key?(:multiple_scopes) && options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        favorites_scope = favorites_scoped(scope).for_favoritable_type favoritable_type
                        results[scope] = favorites_scope = apply_options_to_scope favorites_scope, options
                    end
                else
                    favorites_scope = favorites_scoped(options[:scope]).for_favoritable_type favoritable_type
                    results = favorites_scope = apply_options_to_scope favorites_scope, options
                end
                results
            end

            # Returns the favorite records related to this instance with the favoritable included.
            def all_favorites options = {}
                if options.has_key?(:multiple_scopes) == false
                    results = validate_scopes __method__, options
                elsif options.has_key?(:multiple_scopes) && options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        favorites_scope = favorites_scoped scope
                        results[scope] = favorites_scope = apply_options_to_scope favorites_scope, options
                    end
                else
                    favorites_scope = favorites_scoped options[:scope]
                    results = favorites_scope = apply_options_to_scope favorites_scope, options
                end
                results
            end

            # Returns the actual records which this instance has favorited.
            def all_favorited options = {}
                all_favorites(options).collect{ |f| f.favoritable }
            end

            # Returns the actual records of a particular type which this record has fovarited.
            def favorited_by_type favoritable_type, options = {}
                if options.has_key?(:multiple_scopes) == false
                    options[:parameter] = favoritable_type
                    results = validate_scopes __method__, options
                elsif options.has_key?(:multiple_scopes) && options[:multiple_scopes] == true
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
                    results = favoritables
                end
                results
            end

            def favorited_by_type_count favoritable_type, options = {}
                if options.has_key?(:multiple_scopes) == false
                    options[:parameter] = favoritable_type
                    results = validate_scopes __method__, options
                elsif options.has_key?(:multiple_scopes) && options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = favorites.unblocked.send(scope + '_list').for_favoritable_type(favoritable_type).count
                    end
                else
                    results = favorites.unblocked.send(options[:scope] + '_list').for_favoritable_type(favoritable_type).count
                end
                results
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
                    results = validate_scopes __method__, options
                elsif options.has_key?(:multiple_scopes) && options[:multiple_scopes] == true
                    results = {}
                    options[:scope].each do |scope|
                        results[scope] = favorites.unblocked.send(scope + '_list').for_favoritable(favoritable).first
                    end
                else
                    results = favorites.unblocked.send(options[:scope] + '_list').for_favoritable(favoritable).first
                end
                results
            end

        end

    end
end
