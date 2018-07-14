# frozen_string_literal: true

class Band
  class Punk
    class PopPunk < Band::Punk
      validates_presence_of :name
      acts_as_favoritable
    end
  end
end
