class AddArchivedToPlans < ActiveRecord::Migration[7.2]
  def change
    add_column :plans, :archived, :boolean, default: false, null: false
    add_index  :plans, :archived
  end
end
