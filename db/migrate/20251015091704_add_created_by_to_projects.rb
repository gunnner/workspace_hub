class AddCreatedByToProjects < ActiveRecord::Migration[7.2]
  def up
    add_reference :projects, :created_by, foreign_key: { to_table: :users }, index: true
  end

  def down
    remove_reference :projects, :created_by, foreign_key: { to_table: :users }
  end
end
