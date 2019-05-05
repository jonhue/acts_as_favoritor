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

      def respond_to_missing?(method, include_private = false)
        super || method.to_s[/(.+)_favoritors/] ||
          method.to_s[/favoritable_(.+)_score/] ||
          method.to_s[/favoritable_(.+)_total/]
      end

      def favoritors(scopes: [ActsAsFavoritor.configuration.default_scope])
        self.class.build_result_for_scopes scopes do |scope|
          favorited.includes(:favoritor).unblocked.send("#{scope}_list")
                   .map(&:favoritor)
        end
      end

      def favoritors_by_type(favoritor_type,
                             scopes: [ActsAsFavoritor.configuration
                                                     .default_scope])
        self.class.build_result_for_scopes scopes do |scope|
          favorited.unblocked.send("#{scope}_list")
                   .for_favoritor_type(favoritor_type).map(&:favoritor)
        end
      end

      def favorited_by?(favoritor,
                        scopes: [ActsAsFavoritor.configuration.default_scope])
        self.class.build_result_for_scopes scopes do |scope|
          favorited.unblocked.send("#{scope}_list").for_favoritor(favoritor)
                   .first.present?
        end
      end

      def block(favoritor,
                scopes: [ActsAsFavoritor.configuration.default_scope])
        self.class.build_result_for_scopes scopes do |scope|
          get_favorite_for(favoritor, scope)&.block! || Favorite.create(
            favoritable: self,
            favoritor: favoritor,
            blocked: true,
            scope: scope
          )
        end
      end

      def unblock(favoritor,
                  scopes: [ActsAsFavoritor.configuration.default_scope])
        self.class.build_result_for_scopes scopes do |scope|
          get_favorite_for(favoritor, scope)&.update(blocked: false)
        end
      end

      def blocked?(favoritor,
                   scopes: [ActsAsFavoritor.configuration.default_scope])
        self.class.build_result_for_scopes scopes do |scope|
          favorited.blocked.send("#{scope}_list").for_favoritor(favoritor).first
                   .present?
        end
      end

      def blocked(scopes: [ActsAsFavoritor.configuration.default_scope])
        self.class.build_result_for_scopes scopes do |scope|
          favorited.includes(:favoritor).blocked.send("#{scope}_list")
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
