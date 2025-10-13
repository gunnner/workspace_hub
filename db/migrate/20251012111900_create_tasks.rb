class CreateTasks < ActiveRecord::Migration[7.2]
  def up
    create_table :tasks do |t|
      t.references :project,      null: false, foreign_key: true, index: true
      t.references :organization, null: false, foreign_key: true, index: true
      t.integer    :status,       null: false, default: 0
      t.string     :title,        null: false
      t.text       :description
      t.datetime   :completed_at

      t.timestamps
    end

    add_index :tasks, %i[organization_id project_id]
    add_index :tasks, %i[project_id status]
  end

  def down
    drop_table :tasks, if_exists: true
  end
end
