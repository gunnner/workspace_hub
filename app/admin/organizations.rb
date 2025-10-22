ActiveAdmin.register Organization do
  menu priority: 2

  controller do
    include AdminTenantBypass
  end

  permit_params :name, :subdomain

  index do
    selectable_column
    id_column
    column :name
    column :subdomain do |org|
      link_to org.subdomain, "http://#{org.subdomain}.localhost:3000", target: '_blank'
    end
    column :created_at
    column 'Members' do |org|
      org.users.count
    end
    column 'Projects' do |org|
      org.projects_count
    end
    column 'Plan' do |org|
      org.plan&.name || 'No plan'
    end
    actions
  end

  filter :name
  filter :subdomain
  filter :created_at

  form do |f|
    f.inputs do
      f.input :name
      f.input :subdomain
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :subdomain do |org|
        link_to org.subdomain, "http://#{org.subdomain}.localhost:3000", target: '_blank'
      end
      row :created_at
      row :updated_at
    end

    panel 'Subscription' do
      if organization.subscription
        attributes_table_for organization.subscription do
          row :plan do
            organization.plan.name
          end
          row :status
          row :trial_ends_at
          row :current_period_start
          row :current_period_end
        end
      else
        para 'No active subscription'
      end
    end

    panel 'Members' do
      table_for organization.memberships do
        column 'User' do |membership|
          link_to membership.user.email, admin_user_path(membership.user)
        end
        column :role
        column :created_at
      end
    end

    panel 'Projects' do
      table_for organization.projects.limit(10) do
        column 'Name' do |project|
          link_to project.name, admin_project_path(project)
        end
        column :status
        column :created_at
      end
    end
  end
end
