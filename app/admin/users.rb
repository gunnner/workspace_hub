ActiveAdmin.register User do
  menu priority: 1

  controller do
    include AdminTenantBypass
  end

  permit_params :email, :first_name, :last_name, :password, :password_confirmation

  index do
    selectable_column
    id_column
    column :email
    column :first_name
    column :last_name
    column :created_at
    column 'Organizations' do |user|
      user.organizations.count
    end
    actions
  end

  filter :email
  filter :first_name
  filter :last_name
  filter :created_at

  form do |f|
    f.inputs do
      f.input :email
      f.input :first_name
      f.input :last_name
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :email
      row :first_name
      row :last_name
      row :created_at
      row :updated_at
    end

    panel 'Organizations' do
      table_for user.memberships do
        column 'Organization' do |membership|
          link_to membership.organization.name, admin_organization_path(membership.organization)
        end
        column :role
        column :created_at
      end
    end

    panel 'Projects Created' do
      all_projects = user.organizations.map(&:projects).flatten.uniq.sort_by(&:created_at).reverse.first(10)
      if all_projects.any?
        table_for all_projects do
          column 'Name' do |project|
            link_to project.name, admin_project_path(project)
          end
          column :status do |project|
            status_tag project.status
          end
          column :organization do |project|
            link_to project.organization.name, admin_organization_path(project.organization)
          end
          column :created_at
        end
      else
        para 'No projects found'
      end
    end
  end
end
