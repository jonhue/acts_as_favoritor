class Some < CustomRecord
    validates_presence_of :name
    acts_as_favoritor
    acts_as_favoritable
end
