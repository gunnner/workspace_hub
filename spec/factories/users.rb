FactoryBot.define do
  factory :user do
    sequence(:email)      { |n| "user#{n}@example.com" }
    password              { 'password123' }
    password_confirmation { 'password123' }
    first_name            { 'Adam' }
    last_name             { 'Smith' }

    trait :owner do
      first_name { 'Owner' }
      last_name  { 'User' }
    end

    trait :admin do
      first_name { 'Admin' }
      last_name  { 'User' }
    end

    trait :member do
      first_name { 'Member' }
      last_name  { 'User' }
    end

    trait :viewer do
      first_name { 'Viewer' }
      last_name  { 'User' }
    end
  end
end
