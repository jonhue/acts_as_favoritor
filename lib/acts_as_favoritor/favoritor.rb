# frozen_string_literal: true

module ActsAsFavoritor
  module Favoritor
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def acts_as_favoritor
        has_many :favorites, as: :favoritor, dependent: :destroy
        include ActsAsFavoritor::Favoritor::InstanceMethods
        include ActsAsFavoritor::FavoritorLib

        return unless ActsAsFavoritor.configuration&.cache
        serialize :favoritor_score, Hash
        serialize :favoritor_total, Hash
      end
    end

    module InstanceMethods
      # Returns true if this instance has favorited the object passed as an
      # argument.
      def favorited?(favoritable, options = {})
        if options.key?(:multiple_scopes) == false
          options[:parameter] = favoritable
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            results[scope] = Favorite.unblocked.send(scope.to_s + '_list')
                                     .for_favoritor(self)
                                     .for_favoritable(favoritable).count
                                     .positive?
          end
          results
        else
          Favorite.unblocked.send(options[:scope].to_s + '_list')
                  .for_favoritor(self).for_favoritable(favoritable)
                  .count.positive?
        end
      end

      # Returns true if this instance has blocked the object passed as an
      # argument.
      def blocked?(favoritable, options = {})
        if options.key?(:multiple_scopes) == false
          options[:parameter] = favoritable
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            results[scope] = Favorite.blocked.send(scope + '_list')
                                     .for_favoritor(self)
                                     .for_favoritable(favoritable).count
                                     .positive?
          end
          results
        else
          Favorite.blocked.send(options[:scope] + '_list').for_favoritor(self)
                  .for_favoritable(favoritable).count.positive?
        end
      end

      # Returns true if this instance has favorited the object passed as an
      # argument. Returns nil if this instance has not favorited the object
      # passed as an argument. Returns false if this instance has blocked the
      # object passed as an argument.
      def favorited_type(favoritable, options = {})
        if options.key?(:multiple_scopes) == false
          options[:parameter] = favoritable
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            if Favorite.unblocked.send(scope + '_list').for_favoritor(self)
                       .for_favoritable(favoritable).count.positive?
              results[scope] = true
            elsif Favorite.blocked.send(scope + '_list').for_favoritor(self)
                          .for_favoritable(favoritable).count.positive?
              results[scope] = false
            else
              results[scope] = nil
            end
          end
          results
        elsif Favorite.unblocked.send(options[:scope] + '_list')
                      .for_favoritor(self).for_favoritable(favoritable).count
                      .positive?
          true
        elsif Favorite.blocked.send(options[:scope] + '_list')
                      .for_favoritor(self).for_favoritable(favoritable).count
                      .positive?
          false
        end
      end

      # Returns the number of objects this instance has favorited.
      def favorites_count(options = {})
        if options.key?(:multiple_scopes) == false
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            results[scope] = Favorite.unblocked.send(scope + '_list')
                                     .for_favoritor(self).count
          end
          results
        else
          Favorite.unblocked.send(options[:scope] + '_list')
                  .for_favoritor(self).count
        end
      end

      # Creates a new favorite record for this instance to favorite the passed
      # object. Does not allow duplicate records to be created.
      def favorite(favoritable, options = {})
        if options.key?(:multiple_scopes) == false
          options[:parameter] = favoritable
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            if ActsAsFavoritor.configuration.cache
              favoritor_score[scope] = (favoritor_score[scope] || 0) + 1
              favoritor_total[scope] = (favoritor_total[scope] || 0) + 1
              save!
              favoritable.favoritable_score[scope] =
                (favoritable.favoritable_score[scope] || 0) + 1
              favoritable.favoritable_total[scope] =
                (favoritable.favoritable_total[scope] || 0) + 1
              favoritable.save!
            end
            next unless self != favoritable && scope != 'all'
            params = {
              favoritable_id: favoritable.id,
              favoritable_type: parent_class_name(favoritable),
              scope: scope
            }
            results[scope] = favorites.where(params).first_or_create!
          end
          results
        else
          if ActsAsFavoritor.configuration.cache
            favoritor_score[options[:scope]] =
              (favoritor_score[options[:scope]] || 0) + 1
            favoritor_total[options[:scope]] =
              (favoritor_total[options[:scope]] || 0) + 1
            save!
            favoritable.favoritable_score[options[:scope]] =
              (favoritable.favoritable_score[options[:scope]] || 0) + 1
            favoritable.favoritable_total[options[:scope]] =
              (favoritable.favoritable_total[options[:scope]] || 0) + 1
            favoritable.save!
          end
          if self != favoritable && options[:scope] != 'all'
            params = {
              favoritable_id: favoritable.id,
              favoritable_type: parent_class_name(favoritable),
              scope: options[:scope]
            }
            favorites.where(params).first_or_create!
          end
        end
      end

      # Deletes the favorite record if it exists.
      def remove_favorite(favoritable, options = {})
        if options.key?(:multiple_scopes) == false
          options[:parameter] = favoritable
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            if ActsAsFavoritor.configuration.cache
              favoritor_score[scope] = favoritor_score[scope] - 1
              unless favoritor_score[scope].positive?
                favoritor_score.delete(scope)
              end
              save!
              favoritable.favoritable_score[scope] =
                favoritable.favoritable_score[scope] - 1
              unless favoritable.favoritable_score[scope].positive?
                favoritable.favoritable_score.delete(scope)
              end
              favoritable.save!
            end
            favorite = get_favorite(
              favoritable, scope: scope, multiple_scopes: false
            )
            results[scope] = favorite.destroy if favorite
          end
          results
        else
          if ActsAsFavoritor.configuration.cache
            favoritor_score[options[:scope]] =
              favoritor_score[options[:scope]] - 1
            unless favoritor_score[options[:scope]].positive?
              favoritor_score.delete(options[:scope])
            end
            save!
            favoritable.favoritable_score[options[:scope]] =
              favoritable.favoritable_score[options[:scope]] - 1
            unless favoritable.favoritable_score[options[:scope]].positive?
              favoritable.favoritable_score.delete(options[:scope])
            end
            favoritable.save!
          end
          favorite = get_favorite(
            favoritable, scope: options[:scope], multiple_scopes: false
          )
          favorite&.destroy
        end
      end

      # returns the favorite records to the current instance
      def favorites_scoped(options = {})
        if options.key?(:multiple_scopes) == false
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            results[scope] = favorites.unblocked.send(scope + '_list')
                                      .includes(:favoritable)
          end
          results
        else
          favorites.unblocked.send(options[:scope] + '_list')
                   .includes(:favoritable)
        end
      end

      # Returns the favorite records related to this instance by type.
      def favorites_by_type(favoritable_type, options = {})
        if options.key?(:multiple_scopes) == false
          options[:parameter] = favoritable_type
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            favorites_scope = favorites_scoped(
              scope: scope, multiple_scopes: false
            ).for_favoritable_type(favoritable_type)
            results[scope] = apply_options_to_scope(
              favorites_scope, options
            )
          end
          results
        else
          favorites_scope = favorites_scoped(
            scope: options[:scope], multiple_scopes: false
          ).for_favoritable_type(favoritable_type)
          apply_options_to_scope(
            favorites_scope, options
          )
        end
      end

      # Returns the favorite records related to this instance with the
      # favoritable included.
      def all_favorites(options = {})
        if options.key?(:multiple_scopes) == false
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            favorites_scope = favorites_scoped(
              scope: scope, multiple_scopes: false
            )
            results[scope] = apply_options_to_scope(
              favorites_scope, options
            )
          end
          results
        else
          favorites_scope = favorites_scoped(
            scope: options[:scope], multiple_scopes: false
          )
          apply_options_to_scope(
            favorites_scope, options
          )
        end
      end

      # Returns the actual records which this instance has favorited.
      def all_favorited(options = {})
        if options.key?(:multiple_scopes) == false
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            results[scope] = all_favorites(options).collect(&:favoritable)
          end
          results
        else
          all_favorites(options).collect(&:favoritable)
        end
      end

      # Returns the actual records of a particular type which this record has
      # favorited.
      def favorited_by_type(favoritable_type, options = {})
        if options.key?(:multiple_scopes) == false
          options[:parameter] = favoritable_type
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            favoritables = favoritable_type.constantize.joins(:favorited)
            favoritables = favoritables.where(
              'favorites.blocked': false,
              'favorites.favoritor_id': id,
              'favorites.favoritor_type': parent_class_name(self),
              'favorites.favoritable_type': favoritable_type,
              'favorites.scope': scope
            )
            if options.key?(:limit)
              favoritables = favoritables.limit options[:limit]
            end
            if options.key?(:includes)
              favoritables = favoritables.includes options[:includes]
            end
            results[scope] = favoritables
          end
          results
        else
          favoritables = favoritable_type.constantize.joins(:favorited)
          favoritables = favoritables.where(
            'favorites.blocked': false,
            'favorites.favoritor_id': id,
            'favorites.favoritor_type': parent_class_name(self),
            'favorites.favoritable_type': favoritable_type,
            'favorites.scope': options[:scope]
          )
          if options.key? :limit
            favoritables = favoritables.limit options[:limit]
          end
          if options.key? :includes
            favoritables = favoritables.includes options[:includes]
          end
          favoritables
        end
      end

      def favorited_by_type_count(favoritable_type, options = {})
        if options.key?(:multiple_scopes) == false
          options[:parameter] = favoritable_type
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            results[scope] = favorites.unblocked
                                      .send(scope + '_list')
                                      .for_favoritable_type(favoritable_type)
                                      .count
          end
          results
        else
          favorites.unblocked.send(options[:scope] + '_list')
                   .for_favoritable_type(favoritable_type).count
        end
      end

      # Allows magic names on favorited_by_type
      # e.g. favorited_users == favorited_by_type 'User'
      # Allows magic names on favorited_by_type_count
      # e.g. favorited_users_count == favorited_by_type_count 'User'
      def method_missing(method, *args)
        if method.to_s[/favorited_(.+)_count/]
          favorited_by_type_count $1.singularize.classify
        elsif method.to_s[/favorited_(.+)/]
          favorited_by_type $1.singularize.classify
        elsif ActsAsFavoritor.configuration.cache &&
              method.to_s[/favoritor_(.+)_score/]
          favoritor_score[$1.singularize.classify]
        elsif ActsAsFavoritor.configuration.cache &&
              method.to_s[/favoritor_(.+)_total/]
          favoritor_total[$1.singularize.classify]
        else
          super
        end
      end

      def respond_to_missing?(method, include_private = false)
        super || method.to_s[/favorited_(.+)_count/] ||
          method.to_s[/favorited_(.+)/]
      end

      # Returns a favorite record for the current instance and favoritable
      # object.
      def get_favorite(favoritable, options = {})
        if options.key?(:multiple_scopes) == false
          options[:parameter] = favoritable
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            results[scope] = favorites.unblocked.send(scope.to_s + '_list')
                                      .for_favoritable(favoritable).first
          end
          results
        else
          favorites.unblocked.send(options[:scope].to_s + '_list')
                   .for_favoritable(favoritable).first
        end
      end

      def blocks(options = {})
        if options.key?(:multiple_scopes) == false
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            blocked_favoritors_scope = favoritables_scoped(
              scope: scope, multiple_scopes: false
            ).blocked
            blocked_favoritors_scope = apply_options_to_scope(
              blocked_favoritors_scope, options
            )
            results[scope] = blocked_favoritors_scope.to_a
                                                     .collect(&:favoritable)
          end
          results
        else
          blocked_favoritors_scope = favoritors_scoped(
            scope: options[:scope], multiple_scopes: false
          ).blocked
          blocked_favoritors_scope = apply_options_to_scope(
            blocked_favoritors_scope, options
          )
          blocked_favoritors_scope.to_a.collect(&:favoritable)
        end
      end

      def block(favoritable, options = {})
        if options.key?(:multiple_scopes) == false
          options[:parameter] = favoritable
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            favorite = get_favorite(
              favoritable, scope: scope, multiple_scopes: false
            )
            if favorite
              results[scope] = block_existing_favorite(
                favoritable, scope: scope, multiple_scopes: false
              )
            else
              results[scope] = block_future_favorite(
                favoritable, scope: scope, multiple_scopes: false
              )
            end
          end
          results
        else
          favorite = get_favorite(
            favoritable, scope: options[:scope], multiple_scopes: false
          )
          if favorite
            block_existing_favorite(
              favoritable, scope: options[:scope], multiple_scopes: false
            )
          else
            block_future_favorite(
              favoritable, scope: options[:scope], multiple_scopes: false
            )
          end
        end
      end

      def unblock(favoritable, options = {})
        if options.key?(:multiple_scopes) == false
          options[:parameter] = favoritable
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            results[scope] = get_favorite(
              favoritable, scope: scope, multiple_scopes: false
            )&.update_attribute :blocked, false
          end
          results
        else
          get_favorite(
            favoritable, scope: options[:scope], multiple_scopes: false
          )&.update_attribute :blocked, false
        end
      end

      def blocked_favoritables_count(options = {})
        if options.key?(:multiple_scopes) == false
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            results[scope] = favorites.blocked.send(scope + '_list').count
          end
          results
        else
          favorites.blocked.send(options[:scope] + '_list').count
        end
      end

      private

      def block_future_favorite(favoritable, options = {})
        if options.key?(:multiple_scopes) == false
          options[:parameter] = favoritable
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            results[scope] = Favorite.create(
              favoritable: favoritable,
              favoritor: self,
              blocked: true,
              scope: scope
            )
          end
          results
        else
          Favorite.create(
            favoritable: favoritable,
            favoritor: self,
            blocked: true,
            scope: options[:scope]
          )
        end
      end

      def block_existing_favorite(favoritable, options = {})
        if options.key?(:multiple_scopes) == false
          options[:parameter] = favoritable
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            results[scope] = get_favorite(
              favoritable, scope: scope, multiple_scopes: false
            ).block!
          end
          results
        else
          get_favorite(
            favoritable, scope: options[:scope], multiple_scopes: false
          ).block!
        end
      end
    end
  end
end
