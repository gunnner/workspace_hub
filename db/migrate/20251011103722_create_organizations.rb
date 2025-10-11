class CreateOrganizations < ActiveRecord::Migration[7.2]
  def up
    create_table :organizations do |t|
      t.string :name,      null: false
      t.string :subdomain, null: false, comment: 'Unique subdomain for tenant isolation'

      t.timestamps
    end

    add_index :organizations, :subdomain, unique: true
  end

  def down
    drop_table :organizations, if_exists: true
  end
end
