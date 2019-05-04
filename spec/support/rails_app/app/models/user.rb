# frozen_string_literal: true

class User < ApplicationRecord
  acts_as_favoritor
  acts_as_favoritable

  validates :name, presence: true
end
