# frozen_string_literal: true

module ActsAsFavoritor
  module Favoritable
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def acts_as_favoritable
        if ActsAsFavoritor.configuration&.cache
          serialize :favoritable_score, Hash
          serialize :favoritable_total, Hash
        end

        has_many :favorited, as: :favoritable, dependent: :destroy,
                             class_name: 'Favorite'

        extend ActsAsFavoritor::FavoritorLib
        include ActsAsFavoritor::Favoritable::InstanceMethods
      end
    end

    module InstanceMethods
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def method_missing(method, *args)
        if method.to_s[/(.+)_favoritors/]
          favoritors_by_type($1.singularize.classify)
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
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      # rubocop:disable Style/OptionalBooleanParameter
      def respond_to_missing?(method, include_private = false)
        super || method.to_s[/(.+)_favoritors/] ||
          method.to_s[/favoritable_(.+)_score/] ||
          method.to_s[/favoritable_(.+)_total/]
      end
      # rubocop:enable Style/OptionalBooleanParameter

      def favoritors(scope: ActsAsFavoritor.configuration.default_scope,
                     scopes: nil)
        self.class.build_result_for_scopes(scopes || scope) do |s|
          favorited.includes(:favoritor).unblocked.send("#{s}_list")
                   .map(&:favoritor)
        end
      end

      def favoritors_by_type(favoritor_type,
                             scope: ActsAsFavoritor.configuration.default_scope,
                             scopes: nil)
        self.class.build_result_for_scopes(scopes || scope) do |s|
          favoritor_type.constantize.includes(:favorites)
                        .where(favorites: {
                                 blocked: false, favoritable_id: id,
                                 favoritable_type: self.class.name, scope: s
                               })
        end
      end

      def favorited_by?(favoritor,
                        scope: ActsAsFavoritor.configuration.default_scope,
                        scopes: nil)
        self.class.build_result_for_scopes(scopes || scope) do |s|
          favorited.unblocked.send("#{s}_list").for_favoritor(favoritor)
                   .first.present?
        end
      end

      def block(favoritor, scope: ActsAsFavoritor.configuration.default_scope,
                scopes: nil)
        self.class.build_result_for_scopes(scopes || scope) do |s|
          get_favorite_for(favoritor, s)&.block! || Favorite.create(
            favoritable: self,
            favoritor: favoritor,
            blocked: true,
            scope: scope
          )
        end
      end

      def unblock(favoritor, scope: ActsAsFavoritor.configuration.default_scope,
                  scopes: nil)
        self.class.build_result_for_scopes(scopes || scope) do |s|
          get_favorite_for(favoritor, s)&.update(blocked: false)
        end
      end

      def blocked?(favoritor,
                   scope: ActsAsFavoritor.configuration.default_scope,
                   scopes: nil)
        self.class.build_result_for_scopes(scopes || scope) do |s|
          favorited.blocked.send("#{s}_list").for_favoritor(favoritor).first
                   .present?
        end
      end

      def blocked(scope: ActsAsFavoritor.configuration.default_scope,
                  scopes: nil)
        self.class.build_result_for_scopes(scopes || scope) do |s|
          favorited.includes(:favoritor).blocked.send("#{s}_list")
                   .map(&:favoritor)
        end
      end

      private

      def get_favorite_for(favoritor, scope)
        favorited.send("#{scope}_list").for_favoritor(favoritor).first
      end
    end
  end
end
