# frozen_string_literal: true

class Favorite < ActiveRecord::Base
  extend ActsAsFavoritor::FavoritorLib
  extend ActsAsFavoritor::FavoriteScopes

  belongs_to :favoritable, polymorphic: true
  belongs_to :favoritor, polymorphic: true

  def block!
    update(blocked: true)
  end
end
