FactoryBot.define do
  factory :plan do
    name             { 'Basic Plan' }
    slug             { name.parameterize }
    price_cents      { 2_000 }
    interval         { 'month' }
    features         { {} }
    max_projects     { 10 }
    max_users        { 5 }
    max_storage_mb   { 1_000 }
    api_access       { false }
    priority_support { false }

    trait :free do
      name             { 'Free Plan' }
      slug             { 'free' }
      price_cents      { 0 }
      max_projects     { 3 }
      max_users        { 1 }
      max_storage_mb   { 100 }
      api_access       { false }
      priority_support { false }
    end

    trait :pro do
      name             { 'Pro Plan' }
      slug             { 'pro' }
      price_cents      { 5_000 }
      max_projects     { nil }
      max_users        { nil }
      max_storage_mb   { 10_000 }
      api_access       { true }
      priority_support { true }
    end

    trait :yearly do
      interval    { 'year' }
      price_cents { 20_000 }
    end
  end
end
