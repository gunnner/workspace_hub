FactoryBot.define do
  factory :subscription do
    organization
    plan
    status               { :active }
    current_period_start { Time.current }
    current_period_end   { 1.month.from_now }

    trait :trialing do
      status        { :trialing }
      trial_ends_at { 14.days.from_now }
    end

    trait :canceled do
      status              { :canceled }
      canceled_at         { Time.current }
      cancellation_reason { 'No longer needed' }
    end

    trait :past_due do
      status { :past_due }
    end

    trait :expiring_soon do
      current_period_end { 3.days.from_now }
    end
  end
end
