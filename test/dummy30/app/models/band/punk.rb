# frozen_string_literal: true

class Band
  class Punk < Band
    validates_presence_of :name
    acts_as_favoritable
  end
end
