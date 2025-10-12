class CreateProjects < ActiveRecord::Migration[7.2]
  def change
    create_table :projects do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.string     :name, null: false
      t.text       :description
      t.integer    :status, default: 0, null: false

      t.timestamps
    end

    add_index :projects, %i[organization_id name]
  end

  def down
    drop_table :projects, if_exists: true
  end
end
