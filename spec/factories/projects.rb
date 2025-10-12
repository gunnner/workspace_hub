FactoryBot.define do
  factory :project do
    organization
    name        { Faker::App.name }
    description { Faker::Lorem.paragraph }
    status      { :active }

    after(:build) do |project|
      ActsAsTenant.current_tenant = project.organization if ActsAsTenant.current_tenant.blank? && project.organization.present?
    end
  end
end
