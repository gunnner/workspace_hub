# Seeds for test environment

puts 'Loading test seeds...'

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

puts 'Test seeds loaded!'
