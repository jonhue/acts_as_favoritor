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
                   scope: ActsAsFavoritor.configuration.default_scope,
                   scopes: nil)
        self.class.build_result_for_scopes(scopes || scope) do |s|
          return nil if self == favoritable

          favorites.for_favoritable(favoritable).send("#{s}_list")
                   .first_or_create!

          inc_cache(favoritable, s) if ActsAsFavoritor.configuration.cache
        end
      end

      def unfavorite(favoritable,
                     scope: ActsAsFavoritor.configuration.default_scope,
                     scopes: nil)
        self.class.build_result_for_scopes(scopes || scope) do |s|
          favorite_record = get_favorite(favoritable, s)
          return nil unless favorite_record.present?

          favorite_record.destroy!

          dec_cache(favoritable, s) if ActsAsFavoritor.configuration.cache
        end
      end

      def favorited?(favoritable,
                     scope: ActsAsFavoritor.configuration.default_scope,
                     scopes: nil)
        self.class.build_result_for_scopes(scopes || scope) do |s|
          Favorite.unblocked.send("#{s}_list").for_favoritor(self)
                  .for_favoritable(favoritable).size.positive?
        end
      end

      def all_favorites(scope: ActsAsFavoritor.configuration.default_scope,
                        scopes: nil)
        self.class.build_result_for_scopes(scopes || scope) do |s|
          favorites.unblocked.send("#{s}_list")
        end
      end

      def all_favorited(scope: ActsAsFavoritor.configuration.default_scope,
                        scopes: nil)
        self.class.build_result_for_scopes(scopes || scope) do |s|
          favorites.unblocked.send("#{s}_list").includes(:favoritable)
                   .map(&:favoritable)
        end
      end

      def favorites_by_type(favoritable_type,
                            scope: ActsAsFavoritor.configuration.default_scope,
                            scopes: nil)
        self.class.build_result_for_scopes(scopes || scope) do |s|
          favorites.unblocked.send("#{s}_list")
                   .for_favoritable_type(favoritable_type)
        end
      end

      def favorited_by_type(favoritable_type,
                            scope: ActsAsFavoritor.configuration.default_scope,
                            scopes: nil)
        self.class.build_result_for_scopes(scopes || scope) do |s|
          favoritable_type.constantize.includes(:favorited)
                          .where(favorites: {
                                   blocked: false, favoritor_id: id,
                                   favoritor_type: self.class.name, scope: s
                                 })
        end
      end

      def blocked_by?(favoritable,
                      scope: ActsAsFavoritor.configuration.default_scope,
                      scopes: nil)
        self.class.build_result_for_scopes(scopes || scope) do |s|
          Favorite.blocked.send("#{s}_list").for_favoritor(self)
                  .for_favoritable(favoritable).size.positive?
        end
      end

      def blocked_by(scope: ActsAsFavoritor.configuration.default_scope,
                     scopes: nil)
        self.class.build_result_for_scopes(scopes || scope) do |s|
          favorites.includes(:favoritable).blocked.send("#{s}_list")
                   .map(&:favoritable)
        end
      end

      private

      def get_favorite(favoritable, scope)
        favorites.unblocked.send("#{scope}_list").for_favoritable(favoritable)
                 .first
      end

      # rubocop:disable Metrics/AbcSize
      def inc_cache(favoritable, scope)
        favoritor_score[scope] = (favoritor_score[scope] || 0) + 1
        favoritor_total[scope] = (favoritor_total[scope] || 0) + 1
        save!

        favoritable.favoritable_score[scope] =
          (favoritable.favoritable_score[scope] || 0) + 1
        favoritable.favoritable_total[scope] =
          (favoritable.favoritable_total[scope] || 0) + 1
        favoritable.save!
      end

      def dec_cache(favoritable, scope)
        favoritor_score[scope] = (favoritor_score[scope] || 0) - 1
        favoritor_score.delete(scope) unless favoritor_score[scope].positive?
        save!

        favoritable.favoritable_score[scope] =
          (favoritable.favoritable_score[scope] || 0) - 1
        favoritable.favoritable_score.delete(scope) unless favoritable.favoritable_score[scope].positive?
        favoritable.save!
      end
      # rubocop:enable Metrics/AbcSize
    end
    # rubocop:enable Metrics/ModuleLength
  end
end
