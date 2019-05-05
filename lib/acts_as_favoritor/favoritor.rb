# frozen_string_literal: true

module ActsAsFavoritor
  module Favoritor
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def acts_as_favoritor
        if ActsAsFavoritor.configuration&.cache
          serialize :favoritor_score, Hash
          serialize :favoritor_total, Hash
        end

        has_many :favorites, as: :favoritor, dependent: :destroy

        extend ActsAsFavoritor::FavoritorLib
        include ActsAsFavoritor::Favoritor::InstanceMethods
      end
    end

    # rubocop:disable Metrics/ModuleLength
    module InstanceMethods
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def method_missing(method, *args)
        if method.to_s[/favorited_(.+)/]
          favorited_by_type($1.singularize.classify)
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
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def respond_to_missing?(method, include_private = false)
        super || method.to_s[/favorited_(.+)/] ||
          method.to_s[/favoritor_(.+)_score/] ||
          method.to_s[/favoritor_(.+)_total/]
      end

      def favorite(favoritable,
                   scopes: [ActsAsFavoritor.configuration.default_scope])
        self.class.build_result_for_scopes scopes do |scope|
          return nil if self == favoritable || scope == :all

          inc_cache if ActsAsFavoritor.configuration.cache

          favorites.for_favoritable(favoritable).send("#{scope}_list")
                   .first_or_create!
        end
      end

      def remove_favorite(favoritable,
                          scopes: [ActsAsFavoritor.configuration.default_scope])
        self.class.build_result_for_scopes scopes do |scope|
          dec_cache if ActsAsFavoritor.configuration.cache

          get_favorite(favoritable, scope)&.destroy
        end
      end

      def favorited?(favoritable,
                     scopes: [ActsAsFavoritor.configuration.default_scope])
        self.class.build_result_for_scopes scopes do |scope|
          Favorite.unblocked.send("#{scope}_list").for_favoritor(self)
                  .for_favoritable(favoritable).size.positive?
        end
      end

      def all_favorites(scopes: [ActsAsFavoritor.configuration.default_scope])
        self.class.build_result_for_scopes scopes do |scope|
          favorites.unblocked.send("#{scope}_list")
        end
      end

      def all_favorited(scopes: [ActsAsFavoritor.configuration.default_scope])
        self.class.build_result_for_scopes scopes do |scope|
          favorites.unblocked.send("#{scope}_list").includes(:favoritable)
                   .map(&:favoritable)
        end
      end

      def favorites_by_type(favoritable_type,
                            scopes: [ActsAsFavoritor.configuration
                                                    .default_scope])
        self.class.build_result_for_scopes scopes do |scope|
          favorites.unblocked.send("#{scope}_list").includes(:favoritable)
                   .for_favoritable_type(favoritable_type)
        end
      end

      def favorited_by_type(favoritable_type,
                            scopes: [ActsAsFavoritor.configuration
                                                    .default_scope])
        self.class.build_result_for_scopes scopes do |scope|
          favorites.unblocked.send("#{scope}_list")
                   .for_favoritable_type(favoritable_type).map(&:favoritable)
        end
      end

      def block(favoritable,
                scopes: [ActsAsFavoritor.configuration.default_scope])
        self.class.build_result_for_scopes scopes do |scope|
          get_favorite(favoritable, scope).block! || Favorite.create(
            favoritable: favoritable,
            favoritor: self,
            blocked: true,
            scope: scope
          )
        end
      end

      def unblock(favoritable,
                  scopes: [ActsAsFavoritor.configuration.default_scope])
        self.class.build_result_for_scopes scopes do |scope|
          get_favorite(favoritable, scope)&.update(blocked: false)
        end
      end

      def blocked?(favoritable,
                   scopes: [ActsAsFavoritor.configuration.default_scope])
        self.class.build_result_for_scopes scopes do |scope|
          Favorite.blocked.send("#{scope}_list").for_favoritor(self)
                  .for_favoritable(favoritable).size.positive?
        end
      end

      def blocked(scopes: [ActsAsFavoritor.configuration.default_scope])
        self.class.build_result_for_scopes scopes do |scope|
          favorites.includes(:favoritable).blocked.send("#{scope}_list")
                   .map(&:favoritable)
        end
      end

      private

      def get_favorite(favoritable, scope)
        favorites.unblocked.send("#{scope}_list").for_favoritable(favoritable)
                 .first
      end

      # rubocop:disable Metrics/AbcSize
      def inc_cache
        favoritor_score[scope] = (favoritor_score[scope] || 0) + 1
        favoritor_total[scope] = (favoritor_total[scope] || 0) + 1
        save!

        favoritable.favoritable_score[scope] =
          (favoritable.favoritable_score[scope] || 0) + 1
        favoritable.favoritable_total[scope] =
          (favoritable.favoritable_total[scope] || 0) + 1
        favoritable.save!
      end

      def dec_cache
        favoritor_score[scope] = (favoritor_score[scope] || 0) - 1
        favoritor_score.delete(scope) unless favoritor_score[scope].positive?
        save!

        favoritable.favoritable_score[scope] =
          (favoritable.favoritable_score[scope] || 0) - 1
        # rubocop:disable Metrics/LineLength
        favoritable.favoritable_score.delete(scope) unless favoritable.favoritable_score[scope].positive?
        # rubocop:enable Metrics/LineLength
        favoritable.save!
      end
      # rubocop:enable Metrics/AbcSize
    end
    # rubocop:enable Metrics/ModuleLength
  end
end
