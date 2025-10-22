ActiveAdmin.register Project do
  menu priority: 3

  controller do
    include AdminTenantBypass
  end

  permit_params :name, :description, :status, :organization_id

  scope :all, default: true
  scope :active
  scope('Archived')  { |scope| scope.where(status: :archived) }
  scope('Completed') { |scope| scope.where(status: :completed) }

  index do
    selectable_column
    id_column
    column :name
    column :organization
    column :status do |project|
      status_tag project.status
    end
    column :created_by
    column 'Tasks' do |project|
      project.tasks.count
    end
    column :created_at
    actions
  end

  filter :name
  filter :organization
  filter :status, as: :select, collection: Project.statuses.keys
  filter :created_at

  form do |f|
    f.inputs do
      f.input :organization
      f.input :name
      f.input :description
      f.input :status, as: :select, collection: Project.statuses.keys
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :description
      row :status do
        status_tag project.status
      end
      row :organization do
        link_to project.organization.name, admin_organization_path(project.organization)
      end
      row :created_by do
        link_to project.created_by.email, admin_user_path(project.created_by) if project.created_by
      end
      row :created_at
      row :updated_at
    end

    panel "Tasks (#{project.tasks.count})" do
      table_for project.tasks do
        column 'Title' do |task|
          link_to task.title, admin_task_path(task)
        end
        column :status do |task|
          status_tag task.status
        end
        column :created_at
      end
    end
  end
end
