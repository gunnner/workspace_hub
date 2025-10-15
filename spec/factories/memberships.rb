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

    trait :member do
      role { :member }
    end

    trait :viewer do
      role { :viewer }
    end
  end
end
