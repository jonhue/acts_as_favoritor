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
            def favoritors_count
                self.favorited.unblocked.count
            end

            # Returns the favoritors by a given type
            def favoritors_by_type favoritor_type, options = {}
                favorites = favoritor_type.constantize.
                joins(:favorites).
                where('favorites.blocked': false,
                'favorites.favoritable_id': self.id,
                'favorites.favoritable_type': parent_class_name(self),
                'favorites.favoritor_type': favoritor_type)
                if options.has_key? :limit
                    favorites = favorites.limit options[:limit]
                end
                if options.has_key? :includes
                    favorites = favorites.includes options[:includes]
                end

                favorites
            end

            def favoritors_by_type_count favoritor_type
                self.favorited.unblocked.for_favoritor_type(favoritor_type).count
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

            def blocked_favoritors_count
                self.favorited.blocked.count
            end

            # Returns the favorited records scoped
            def favoritors_scoped
                self.favorited.includes :favoritor
            end

            def favoritors options = {}
                favoritors_scope = favoritors_scoped.unblocked
                favoritors_scope = apply_options_to_scope favoritors_scope, options
                favoritors_scope.to_a.collect{ |f| f.favoritor }
            end

            def blocks options = {}
                blocked_favoritors_scope = favoritors_scoped.blocked
                blocked_favoritors_scope = apply_options_to_scope blocked_favoritors_scope, options
                blocked_favoritors_scope.to_a.collect{ |f| f.favoritor }
            end

            # Returns true if the current instance is favorited by the passed record
            # Returns false if the current instance is blocked by the passed record or no favorite is found
            def favorited_by? favoritor
                self.favorited.unblocked.for_favoritor(favoritor).first.present?
            end

            def block favoritor
                get_favorite_for(favoritor) ? block_existing_favorite(favoritor) : block_future_favorite(favoritor)
            end

            def unblock favoritor
                get_favorite_for(favoritor).update_attribute :blocked, false
            end

            def get_favorite_for favoritor
                self.favorited.for_favoritor(favoritor).first
            end

            private

            def block_future_favorite favoritor
                Favorite.create favoritable: self, favoritor: favoritor, blocked: true
            end

            def block_existing_favorite favoritor
                get_favorite_for(favoritor).block!
            end

        end

    end
end
