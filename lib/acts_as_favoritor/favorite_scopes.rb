# frozen_string_literal: true

module ActsAsFavoritor
  module FavoriteScopes
    DEFAULT_PARENTS = [ApplicationRecord, ActiveRecord::Base].freeze

    def method_missing(method, *args)
      if method.to_s[/(.+)_list/]
        where(scope: $1.singularize.to_sym)
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      super || method.to_s[/(.+)_list/]
    end

    def for_favoritor(favoritor)
      where(
        favoritor_id: favoritor.id,
        favoritor_type: parent_class_name(favoritor)
      )
    end

    def for_favoritable(favoritable)
      where(
        favoritable_id: favoritable.id,
        favoritable_type: parent_class_name(favoritable)
      )
    end

    def for_favoritor_type(favoritor_type)
      where(favoritor_type:)
    end

    def for_favoritable_type(favoritable_type)
      where(favoritable_type:)
    end

    def unblocked
      where(blocked: false)
    end

    def blocked
      where(blocked: true)
    end

    private

    def parent_class_name(object)
      if DEFAULT_PARENTS.include?(object.class.superclass) ||
         !object.class.respond_to?(:base_class)
        return object.class.name
      end

      object.class.base_class.name
    end
  end
end
