class CreateMemberships < ActiveRecord::Migration[7.2]
  def up
    create_table :memberships do |t|
      t.references :user,         null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.integer    :role,         null: false, default: 0

      t.timestamps
    end

    add_index :memberships, %i[user_id organization_id], unique: true
  end

  def down
    drop_table :memberships, if_exists: true
  end
end
