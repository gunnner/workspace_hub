class AddCustomFieldsToUsers < ActiveRecord::Migration[7.2]
  def up
    add_column :users, :first_name, :string
    add_column :users, :last_name,  :string
    add_column :users, :avatar_url, :string
    add_column :users, :api_token,  :string

    add_index :users, :api_token, unique: true
  end

  def down
    remove_index :users, :api_token

    remove_column :users, :first_name, if_exists: true
    remove_column :users, :last_name,  if_exists: true
    remove_column :users, :avatar_url, if_exists: true
    remove_column :users, :api_token,  if_exists: true
  end
end
