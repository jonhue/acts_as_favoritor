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
                if options[:multiple_scopes].nil?
                    results = validate_scopes __method__, options[:scope]
                elsif options[:multiple_scopes]
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
                scopes = options[:scope] || [:favorites]
                scopes.each do |scope|
                    favorites = favoritor_type.constantize.joins(:favorites).where('favorites.blocked': false,
                        'favorites.favoritable_id': id,
                        'favorites.favoritable_type': parent_class_name(self),
                        'favorites.favoritor_type': favoritor_type,
                        'favorites.scope': scope)
                    if options.has_key? :limit
                        favorites = favorites.limit options[:limit]
                    end
                    if options.has_key? :includes
                        favorites = favorites.includes options[:includes]
                    end
                    favorites
                end
            end

            def favoritors_by_type_count favoritor_type, options = {}
                scopes = options[:scope] || [:favorites]
                scopes.each do |scope|
                    favorited.unblocked.send(scope + '_list').for_favoritor_type(favoritor_type).count
                end
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
                scopes = options[:scope] || [:favorites]
                scopes.each do |scope|
                    favorited.blocked.send(scope + '_list').count
                end
            end

            # Returns the favorited records scoped
            def favoritors_scoped options = {}
                scopes = options[:scope] || [:favorites]
                scopes.each do |scope|
                    favorited.send(scope + '_list').includes :favoritor
                end
            end

            def favoritors options = {}
                scopes = options[:scope] || [:favorites]
                scopes.each do |scope|
                    favoritors_scope = favoritors_scoped(scope).unblocked
                    favoritors_scope = apply_options_to_scope favoritors_scope, options
                    favoritors_scope.to_a.collect{ |f| f.favoritor }
                end
            end

            def blocks options = {}
                scopes = options[:scope] || [:favorites]
                scopes.each do |scope|
                    blocked_favoritors_scope = favoritors_scoped(scope).blocked
                    blocked_favoritors_scope = apply_options_to_scope blocked_favoritors_scope, options
                    blocked_favoritors_scope.to_a.collect{ |f| f.favoritor }
                end
            end

            # Returns true if the current instance is favorited by the passed record
            # Returns false if the current instance is blocked by the passed record or no favorite is found
            def favorited_by? favoritor, options = {}
                scopes = options[:scope] || [:favorites]
                scopes.each do |scope|
                    favorited.unblocked.send(scope + '_list').for_favoritor(favoritor).first.present?
                end
            end

            def block favoritor, options = {}
                scopes = options[:scope] || [:favorites]
                scopes.each do |scope|
                    get_favorite_for(favoritor, scope: scope) ? block_existing_favorite(favoritor, scope: scope) : block_future_favorite(favoritor, scope: scope)
                end
            end

            def unblock favoritor, options = {}
                scopes = options[:scope] || [:favorites]
                scopes.each do |scope|
                    get_favorite_for(favoritor, scope: scope).update_attribute :blocked, false
                end
            end

            def get_favorite_for favoritor, options = {}
                scopes = options[:scope] || [:favorites]
                scopes.each do |scope|
                    favorited.send(scope + '_list').for_favoritor(favoritor).first
                end
            end

            private

            def block_future_favorite favoritor, options = {}
                scopes = options[:scope] || [:favorites]
                scopes.each do |scope|
                    Favorite.create favoritable: self, favoritor: favoritor, blocked: true, scope: scope
                end
            end

            def block_existing_favorite favoritor, options = {}
                scopes = options[:scope] || [:favorites]
                scopes.each do |scope|
                    get_favorite_for(favoritor, scope: scope).block!
                end
            end

        end

    end
end
