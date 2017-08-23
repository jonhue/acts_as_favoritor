class Favorite < ActiveRecord::Base

    extend ActsAsFavoritor::FavoritorLib
    extend ActsAsFavoritor::FavoriteScopes

    # send(scope + '_list') - returns favorite records of scope
    Favorite.group(:scope).each do |s|
        scope s + '_list', -> { where(scope: s) }
    end
    scope :all_list, -> { all }

    # NOTE: Favorites belong to the 'favoritable' and 'favoritor' interface
    belongs_to :favoritable, polymorphic: true
    belongs_to :favoritor, polymorphic: true

    def block!
        self.update_attribute :blocked, true
    end

end
