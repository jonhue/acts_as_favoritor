module ActsAsFavoritor #:nodoc:
    module FavoriteScopes

        # send(scope + '_list') - returns favorite records of scope
        Favorite.all.group_by(&:scope).each do |s|
            Favorite.send(:define_method, "#{s}_list") do
                where scope: s
            end
        end
        def favorites_list
            where scope: 'favorites'
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
