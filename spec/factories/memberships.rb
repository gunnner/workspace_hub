FactoryBot.define do
  factory :membership do
    user
    organization
    role { :member }

    trait :admin do
      role { :admin }
    end

    trait :owner do
      role { :owner }
    end
  end
end
