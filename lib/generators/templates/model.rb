class Favorite < ActiveRecord::Base

    extend ActsAsFavoritor::FavoritorLib
    extend ActsAsFavoritor::FavoriteScopes

    serialize :types

    # NOTE: Follows belong to the 'favoritable' and 'favoritor' interface
    belongs_to :favoritable, polymorphic: true
    belongs_to :favoritor, polymorphic: true

    def block!
        self.update_attribute :blocked, true
    end

end
