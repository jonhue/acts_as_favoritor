# frozen_string_literal: true

module ActsAsFavoritor
  module FavoriteScopes
    # Allows magic names on send(scope + '_list') - returns favorite records of certain scope
    # e.g. favoritors == favoritors.send('favorite_list')
    def method_missing m, *args
      if m.to_s[/(.+)_list/]
        where scope: $1.singularize
      else
        super
      end
    end

    def respond_to? m, include_private = false
      super || m.to_s[/(.+)_list/]
    end

    def all_list
      all
    end

    # returns favorite records where favoritor is the record passed in.
    def for_favoritor favoritor
      where favoritor_id: favoritor.id, favoritor_type: parent_class_name(favoritor)
    end

    # returns favorite records where favoritable is the record passed in.
    def for_favoritable favoritable
      where favoritable_id: favoritable.id, favoritable_type: parent_class_name(favoritable)
    end

    # returns favorite records where favoritor_type is the record passed in.
    def for_favoritor_type favoritor_type
      where favoritor_type: favoritor_type
    end

    # returns favorite records where favoritable_type is the record passed in.
    def for_favoritable_type favoritable_type
      where favoritable_type: favoritable_type
    end

    # returns favorite records from past 2 weeks with default parameter.
    def recent from
      where ['created_at > ?', (from || 2.weeks.ago).to_s(:db)]
    end

    # returns favorite records in descending order.
    def descending
      order 'favorites.created_at desc'
    end

    # returns unblocked favorite records.
    def unblocked
      where blocked: false
    end

    # returns blocked favorite records.
    def blocked
      where blocked: true
    end
  end
end
