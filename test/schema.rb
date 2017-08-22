ActiveRecord::Schema.define version: 0 do

    create_table :favorites, force: true do |t|
        t.integer  'favoritable_id', null: false
        t.string   'favoritable_type', null: false
        t.integer  'favoritor_id', null: false
        t.string   'favoritor_type', null: false
        t.string :scope, default: 'favorites', null: false
        t.boolean  'blocked', default: false, null: false
        t.datetime 'created_at'
        t.datetime 'updated_at'
    end

    create_table :users, force: true do |t|
        t.column :name, :string
    end

    create_table :bands, force: true do |t|
        t.column :name, :string
    end

    create_table :somes, force: true do |t|
        t.column :name, :string
    end

end
