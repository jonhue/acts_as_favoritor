# frozen_string_literal: true

class Band::Punk::PopPunk < Band::Punk
  validates_presence_of :name
  acts_as_favoritable
end
