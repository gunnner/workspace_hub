ActiveAdmin.register_page 'Dashboard' do
  menu priority: 1, label: proc { I18n.t('active_admin.dashboard') }

  controller do
    include AdminTenantBypass
  end

  content title: proc { I18n.t('active_admin.dashboard') } do
    columns do
      column do
        panel 'Statistics' do
          para "Total Organizations: #{Organization.count}"
          para "Total Users: #{User.count}"
          para "Total Projects: #{Project.count}"
          para "Total Tasks: #{Task.count}"
        end
      end

      column do
        panel 'Recent Projects' do
          table_for Project.order(created_at: :desc).limit(5) do
            column('Name')         { |project| link_to project.name, admin_project_path(project) }
            column('Organization') { |project| project.organization.name }
            column('Status')       { |project| status_tag project.status }
          end
        end
      end

      column do
        panel 'Recent Organizations' do
          table_for Organization.order(created_at: :desc).limit(5) do
            column('Name')      { |org| link_to org.name, admin_organization_path(org) }
            column('Subdomain') { |org| org.subdomain }
            column('Members')   { |org| org.users.count }
            column('Created')   { |org| org.created_at.strftime('%b %d, %Y') }
          end
        end
      end
    end
  end
end
