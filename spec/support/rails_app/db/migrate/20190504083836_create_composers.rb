class CreateComposers < ActiveRecord::Migration[5.2]
  def change
    create_table :composers do |t|
      t.string :name
    end
  end
end
