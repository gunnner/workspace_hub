FactoryBot.define do
  factory :organization do
    sequence(:name)      { |n| "Organization #{n}" }
    sequence(:subdomain) { |n| "org-#{n}-#{SecureRandom.hex(4)}" }

    after(:build) do |organization|
      def organization.create_free_subscription; end
    end

    trait :with_subscription do
      after(:build) do |organization|
        organization.singleton_class.class_eval do
          remove_method(:create_free_subscription)
        end
      end
    end

    trait :with_owner do
      transient do
        owner { nil }
      end

      after(:create) do |organization, evaluator|
        user = evaluator.owner || create(:user)
        create(:membership, :owner, user: user, organization: organization, role: :owner)
      end
    end
  end
end
