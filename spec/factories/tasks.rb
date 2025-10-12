FactoryBot.define do
  factory :task do
    project
    title       { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph }
    status      { :todo }

    after(:build) do |task|
      task.organization ||= task.project&.organization

      ActsAsTenant.current_tenant = task.organization if ActsAsTenant.current_tenant.blank? && task.organization.present?
    end

    trait :completed do
      status       { :completed }
      completed_at { Time.current }
    end

    trait :in_progress do
      status { :in_progress }
    end
  end
end
