FactoryBot.define do
  factory :organization do
    sequence(:name)      { |n| "Organization #{n}" }
    sequence(:subdomain) { |n| "org-#{n}-#{SecureRandom.hex(4)}" }

    after(:build) do |organization|
      def organization.create_free_subscription; end
    end

    after(:create) do |organization|
      owner = create(:user, email: "owner_#{organization.id}@example.com")
      create(:membership, :owner, user: owner, organization: organization)
    end

    trait :with_subscription do
      after(:create) do |organization|
        subscription = organization.subscription || organization.build_subscription
        subscription.update!(
          plan: Plan.find_by(slug: 'free') || create(:plan, slug: 'free'),
          status:               :active,
          current_period_start: Time.current,
          current_period_end:   1.month.from_now,
          trial_ends_at:        3.days.from_now
        )
      end
    end
  end
end
