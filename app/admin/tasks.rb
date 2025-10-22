ActiveAdmin.register Task do
  menu priority: 4

  controller do
    include AdminTenantBypass
  end

  permit_params :title, :description, :status, :project_id, :completed_at

  index do
    selectable_column
    id_column
    column :title
    column :project
    column :status do |task|
      status_tag task.status
    end
    column :completed_at
    column :created_at
    actions
  end

  filter :title
  filter :project
  filter :status, as: :select, collection: Task.statuses.keys
  filter :created_at

  form do |f|
    f.inputs do
      f.input :project
      f.input :title
      f.input :description
      f.input :status, as: :select, collection: Task.statuses.keys
      f.input :completed_at, as: :datepicker
    end
    f.actions
  end
end
