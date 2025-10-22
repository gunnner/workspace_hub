ActiveAdmin.register Plan do
  menu priority: 5

  controller do
    include AdminTenantBypass
  end

  permit_params :name, :slug, :price_cents, :interval, :max_projects, :max_users, :max_storage_mb, :features, :archived, :api_access, :priority_support

  index do
    selectable_column
    id_column
    column :name
    column :slug
    column :price do |plan|
      number_to_currency(plan.price_cents / 100.0)
    end
    column :interval
    column :max_projects
    column :max_users
    column :archived do |plan|
      status_tag plan.archived
    end
    column 'Subscribers' do |plan|
      plan.subscriptions.count
    end
    actions
  end

  filter :name
  filter :slug
  filter :archived

  show do
    attributes_table do
      row :id
      row :name
      row :slug
      row :price do
        number_to_currency(plan.price_cents / 100.0)
      end
      row :interval
      row :max_projects
      row :max_users
      row :max_storage_mb
      row :features
      row :api_access
      row :priority_support
      row :archived do
        status_tag plan.archived
      end
      row :created_at
      row :updated_at
    end

    panel "Subscriptions (#{plan.subscriptions.count})" do
      table_for plan.subscriptions.limit(20) do
        column 'Organization' do |subscription|
          link_to subscription.organization.name, admin_organization_path(subscription.organization)
        end
        column :status
        column :created_at
      end
    end
  end
end
