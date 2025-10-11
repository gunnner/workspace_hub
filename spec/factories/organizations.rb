FactoryBot.define do
  factory :organization do
    name { Faker::Company.name }
    subdomain { Faker::Internet.unique.domain_word.downcase.gsub('_', '-') }

    trait :with_owner do
      transient do
        owner { nil }
      end

      after(:create) do |organization, evaluator|
        user = evaluator.owner || create(:user)
        create(:membership, :owner, user: user, organization: organization)
      end
    end
  end
end
