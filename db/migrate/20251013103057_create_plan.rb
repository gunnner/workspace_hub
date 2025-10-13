class CreatePlan < ActiveRecord::Migration[7.2]
  def up
    create_table :plans do |t|
      t.string  :name,        null: false
      t.string  :slug,        null: false
      t.integer :price_cents, null: false, default: 0
      t.string  :interval,    null: false, default: 'month'
      t.jsonb   :features,                 default: {}
      t.boolean :api_access,               default: false
      t.boolean :priority_support,         default: false
      t.integer :max_projects
      t.integer :max_users
      t.integer :max_storage_mb

      t.timestamps
    end

    add_index :plans, :slug, unique: true
    add_index :plans, :price_cents
  end

  def down
    drop_table :plans, if_exists: true
  end
end
