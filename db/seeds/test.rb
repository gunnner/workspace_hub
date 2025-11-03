# Seeds for test environment

puts 'Loading test seeds...'

# Create plans
Plan.find_or_create_by!(slug: 'free') do |plan|
  plan.name = 'Free Plan'
  plan.price_cents = 0
  plan.interval = 'month'
  plan.max_projects = 3
  plan.max_users = 1
  plan.max_storage_mb = 100
  plan.api_access = false
  plan.priority_support = false
  plan.archived = false
  plan.features = { 'projects' => true, 'tasks' => true }
end

Plan.find_or_create_by!(slug: 'basic') do |plan|
  plan.name = 'Basic Plan'
  plan.price_cents = 2000
  plan.interval = 'month'
  plan.max_projects = 10
  plan.max_users = 5
  plan.max_storage_mb = 1000
  plan.api_access = false
  plan.priority_support = false
  plan.archived = false
  plan.features = { 'projects' => true, 'tasks' => true, 'reports' => true }
end

Plan.find_or_create_by!(slug: 'pro') do |plan|
  plan.name = 'Pro Plan'
  plan.price_cents = 5000
  plan.interval = 'month'
  plan.max_projects = nil
  plan.max_users = nil
  plan.max_storage_mb = nil
  plan.api_access = true
  plan.priority_support = true
  plan.archived = false
  plan.features = { 'projects' => true, 'tasks' => true, 'reports' => true, 'api' => true }
end

puts '3 plans created'
puts 'Test seeds loaded!'
