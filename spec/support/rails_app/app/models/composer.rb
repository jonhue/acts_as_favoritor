# frozen_string_literal: true

class Composer < ApplicationRecord
  acts_as_favoritable

  validates :name, presence: true
end
