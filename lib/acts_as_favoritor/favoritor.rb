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
                scopes = options[:scope] || [:favorites]
                scopes.each do |scope|
                    0 < Favorite.unblocked.send(scope + '_list').for_favoritor(self).for_favoritable(favoritable).count
                end
            end

            # Returns the number of objects this instance has favorited.
            def favorites_count options = {}
                scopes = options[:scope] || [:favorites]
                scopes.each do |scope|
                    Favorite.unblocked.send(scope + '_list').for_favoritor(self).count
                end
            end

            # Creates a new favorite record for this instance to favorite the passed object.
            # Does not allow duplicate records to be created.
            def favorite favoritable, options = {}
                scopes = options[:scope] || [:favorites]
                scopes.each do |scope|
                    if self != favoritable && scope != 'all'
                        params = {favoritable_id: favoritable.id, favoritable_type: parent_class_name(favoritable), scope: scope}
                        favorites.where(params).first_or_create!
                    end
                end
            end

            # Deletes the favorite record if it exists.
            def remove_favorite favoritable, options = {}
                scopes = options[:scope] || [:favorites]
                scopes.each do |scope|
                    if favorite = get_favoritor(favoritable).send(scope + '_list')
                        favorite.destroy
                    end
                end
            end

            # returns the favorite records to the current instance
            def favorites_scoped options = {}
                scopes = options[:scope] || [:favorites]
                scopes.each do |scope|
                    favorites.unblocked.send(scope + '_list').includes :favoritable
                end
            end

            # Returns the favorite records related to this instance by type.
            def favorites_by_type favoritable_type, options = {}
                scopes = options[:scope] || [:favorites]
                scopes.each do |scope|
                    favorites_scope = favorites_scoped(scope).for_favoritable_type favoritable_type
                    favorites_scope = apply_options_to_scope favorites_scope, options
                end
            end

            # Returns the favorite records related to this instance with the favoritable included.
            def all_favorites options = {}
                scopes = options[:scope] || [:favorites]
                scopes.each do |scope|
                    favorites_scope = favorites_scoped scope
                    favorites_scope = apply_options_to_scope favorites_scope, options
                end
            end

            # Returns the actual records which this instance has favorited.
            def all_favorited options = {}
                scopes = options[:scope] || [:favorites]
                scopes.each do |scope|
                    all_favorites(options).collect{ |f| f.favoritable }
                end
            end

            # Returns the actual records of a particular type which this record has fovarited.
            def favorited_by_type favoritable_type, options = {}
                scopes = options[:scope] || [:favorites]
                scopes.each do |scope|
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
                    favoritables
                end
            end

            def favorited_by_type_count favoritable_type, options = {}
                scopes = options[:scope] || [:favorites]
                scopes.each do |scope|
                    favorites.unblocked.send(scope + '_list').for_favoritable_type(favoritable_type).count
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
                scopes = options[:scope] || [:favorites]
                scopes.each do |scope|
                    favorites.unblocked.send(scope + '_list').for_favoritable(favoritable).first
                end
            end

        end

    end
end
