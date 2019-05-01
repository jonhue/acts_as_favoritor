# frozen_string_literal: true

module ActsAsFavoritor
  module Favoritable
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def acts_as_favoritable
        has_many :favorited,
                 as: :favoritable, dependent: :destroy, class_name: 'Favorite'
        include ActsAsFavoritor::Favoritable::InstanceMethods
        include ActsAsFavoritor::FavoritorLib

        return unless ActsAsFavoritor.configuration&.cache

        serialize :favoritable_score, Hash
        serialize :favoritable_total, Hash
      end
    end

    module InstanceMethods
      # Returns the number of favoritors a record has.
      def favoritors_count(options = {})
        if options.key?(:multiple_scopes) == false
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            results[scope] = favorited.unblocked.send(scope + '_list').count
          end
          results
        else
          favorited.unblocked.send(options[:scope] + '_list').count
        end
      end

      # Returns the favoritors by a given type.
      def favoritors_by_type(favoritor_type, options = {})
        if options.key?(:multiple_scopes) == false
          options[:parameter] = favoritor_type
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            favorites = favoritor_type.constantize.joins(:favorites)
            favorites = favorites.where(
              'favorites.blocked': false,
              'favorites.favoritable_id': id,
              'favorites.favoritable_type': parent_class_name(self),
              'favorites.favoritor_type': favoritor_type,
              'favorites.scope': scope
            )
            favorites = favorites.limit(options[:limit]) if options.key?(:limit)
            if options.key?(:includes)
              favorites = favorites.includes(options[:includes])
            end
            results[scope] = favorites
          end
          results
        else
          favorites = favoritor_type.constantize.joins(:favorites)
          favorites = favorites.where(
            'favorites.blocked': false,
            'favorites.favoritable_id': id,
            'favorites.favoritable_type': parent_class_name(self),
            'favorites.favoritor_type': favoritor_type,
            'favorites.scope': options[:scope]
          )
          favorites = favorites.limit(options[:limit]) if options.key?(:limit)
          if options.key?(:includes)
            favorites = favorites.includes(options[:includes])
          end
          favorites
        end
      end

      def favoritors_by_type_count(favoritor_type, options = {})
        if options.key?(:multiple_scopes) == false
          options[:parameter] = favoritor_type
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            results[scope] = favorited.unblocked.send(scope + '_list')
                                      .for_favoritor_type(favoritor_type).count
          end
          results
        else
          favorited.unblocked.send(options[:scope] + '_list')
                   .for_favoritor_type(favoritor_type).count
        end
      end

      # Allows magic names on favoritors_by_type
      # e.g. user_favoritors == favoritors_by_type 'User'
      # Allows magic names on favoritors_by_type_count
      # e.g. count_user_favoritors == favoritors_by_type_count 'User'
      def method_missing(method, *args)
        if method.to_s[/count_(.+)_favoritors/]
          favoritors_by_type_count $1.singularize.classify
        elsif method.to_s[/(.+)_favoritors/]
          favoritors_by_type $1.singularize.classify
        elsif ActsAsFavoritor.configuration.cache &&
              method.to_s[/favoritable_(.+)_score/]
          favoritable_score[$1.singularize.classify]
        elsif ActsAsFavoritor.configuration.cache &&
              method.to_s[/favoritable_(.+)_total/]
          favoritable_total[$1.singularize.classify]
        else
          super
        end
      end

      def respond_to_missing?(method, include_private = false)
        super || method.to_s[/count_(.+)_favoritors/] ||
          method.to_s[/(.+)_favoritors/]
      end

      def blocked_favoritors_count(options = {})
        if options.key?(:multiple_scopes) == false
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            results[scope] = favorited.blocked.send(scope + '_list').count
          end
          results
        else
          favorited.blocked.send(options[:scope] + '_list').count
        end
      end

      # Returns the favorited records scoped.
      def favoritors_scoped(options = {})
        if options.key?(:multiple_scopes) == false
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            results[scope] = favorited.send(scope + '_list')
                                      .includes(:favoritor)
          end
          results
        else
          favorited.send(options[:scope] + '_list').includes(:favoritor)
        end
      end

      def favoritors(options = {})
        if options.key?(:multiple_scopes) == false
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            favoritors_scope = favoritors_scoped(
              scope: scope, multiple_scopes: false
            ).unblocked
            favoritors_scope = apply_options_to_scope(
              favoritors_scope, options
            )
            results[scope] = favoritors_scope.to_a.collect(&:favoritor)
          end
          results
        else
          favoritors_scope = favoritors_scoped(
            scope: options[:scope], multiple_scopes: false
          ).unblocked
          favoritors_scope = apply_options_to_scope(
            favoritors_scope, options
          )
          favoritors_scope.to_a.collect(&:favoritor)
        end
      end

      def blocks(options = {})
        if options.key?(:multiple_scopes) == false
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            blocked_favoritors_scope = favoritors_scoped(
              scope: scope, multiple_scopes: false
            ).blocked
            blocked_favoritors_scope = apply_options_to_scope(
              blocked_favoritors_scope, options
            )
            results[scope] = blocked_favoritors_scope.to_a.collect(&:favoritor)
          end
          results
        else
          blocked_favoritors_scope = favoritors_scoped(
            scope: options[:scope], multiple_scopes: false
          ).blocked
          blocked_favoritors_scope = apply_options_to_scope(
            blocked_favoritors_scope, options
          )
          blocked_favoritors_scope.to_a.collect(&:favoritor)
        end
      end

      # Returns true if the current instance has blocked the passed record.
      # Returns false if the current instance has not blocked the passed record.
      def blocked?(favoritor, options = {})
        if options.key?(:multiple_scopes) == false
          options[:parameter] = favoritor
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            results[scope] = favorited.blocked.send(scope + '_list')
                                      .for_favoritor(favoritor).first.present?
          end
          results
        else
          favorited.blocked.send(options[:scope] + '_list')
                   .for_favoritor(favoritor).first.present?
        end
      end

      # Returns true if the current instance is favorited by the passed record.
      # Returns false if the current instance is blocked by the passed record or
      # no favorite is found.
      def favorited_by?(favoritor, options = {})
        if options.key?(:multiple_scopes) == false
          options[:parameter] = favoritor
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            results[scope] = favorited.unblocked.send(scope + '_list')
                                      .for_favoritor(favoritor).first.present?
          end
          results
        else
          favorited.unblocked.send(options[:scope] + '_list')
                   .for_favoritor(favoritor).first.present?
        end
      end

      # Returns true if this instance has been favorited by the object passed as
      # an argument. Returns nil if this instance has not been favorited by the
      # object passed as an argument. Returns false if this instance has blocked
      # the object passed as an argument.
      def favoritor_type(favoritor, options = {})
        if options.key?(:multiple_scopes) == false
          options[:parameter] = favoritor
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            if favorited.unblocked.send(scope + '_list')
                        .for_favoritor(favoritor).first.present?
              results[scope] = true
            elsif favorited.blocked.send(scope + '_list')
                           .for_favoritor(favoritor).first.present?
              results[scope] = false
            else
              results[scope] = nil
            end
          end
          results
        elsif favorited.unblocked.send(options[:scope] + '_list')
                       .for_favoritor(favoritor).first.present?
          true
        elsif favorited.blocked.send(options[:scope] + '_list')
                       .for_favoritor(favoritor).first.present?
          false
        end
      end

      def block(favoritor, options = {})
        if options.key?(:multiple_scopes) == false
          options[:parameter] = favoritor
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            favorite = get_favorite_for(
              favoritor, scope: scope, multiple_scopes: false
            )
            results[scope] = if favorite
                               block_existing_favorite(
                                 favoritor, scope: scope, multiple_scopes: false
                               )
                             else
                               block_future_favorite(
                                 favoritor, scope: scope, multiple_scopes: false
                               )
                             end
          end
          results
        else
          favorite = get_favorite_for(
            favoritor, scope: options[:scope], multiple_scopes: false
          )
          if favorite
            block_existing_favorite(
              favoritor, scope: options[:scope], multiple_scopes: false
            )
          else
            block_future_favorite(
              favoritor, scope: options[:scope], multiple_scopes: false
            )
          end
        end
      end

      def unblock(favoritor, options = {})
        if options.key?(:multiple_scopes) == false
          options[:parameter] = favoritor
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            results[scope] = get_favorite_for(
              favoritor, scope: scope, multiple_scopes: false
            )&.update(blocked: false)
          end
          results
        else
          get_favorite_for(
            favoritor, scope: options[:scope], multiple_scopes: false
          )&.update(blocked: false)
        end
      end

      def get_favorite_for(favoritor, options = {})
        if options.key?(:multiple_scopes) == false
          options[:parameter] = favoritor
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            results[scope] = favorited.send(scope + '_list')
                                      .for_favoritor(favoritor).first
          end
          results
        else
          favorited.send(options[:scope] + '_list').for_favoritor(favoritor)
                   .first
        end
      end

      private

      def block_future_favorite(favoritor, options = {})
        if options.key?(:multiple_scopes) == false
          options[:parameter] = favoritor
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            results[scope] = Favorite.create(
              favoritable: self,
              favoritor: favoritor,
              blocked: true,
              scope: scope
            )
          end
          results
        else
          Favorite.create(
            favoritable: self,
            favoritor: favoritor,
            blocked: true,
            scope: options[:scope]
          )
        end
      end

      def block_existing_favorite(favoritor, options = {})
        if options.key?(:multiple_scopes) == false
          options[:parameter] = favoritor
          validate_scopes(__method__, options)
        elsif options[:multiple_scopes]
          results = {}
          options[:scope].each do |scope|
            results[scope] = get_favorite_for(
              favoritor, scope: scope, multiple_scopes: false
            ).block!
          end
          results
        else
          get_favorite_for(
            favoritor, scope: options[:scope], multiple_scopes: false
          ).block!
        end
      end
    end
  end
end
