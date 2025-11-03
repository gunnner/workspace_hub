puts "Seeding #{Rails.env} environment..."
puts '=' * 80
puts 'Creating plans...'

free_plan = Plan.find_or_create_by!(slug: 'free') do |plan|
  plan.name             = 'Free Plan'
  plan.price_cents      = 0
  plan.interval         = 'month'
  plan.max_projects     = 3
  plan.max_users        = 1
  plan.max_storage_mb   = 100
  plan.api_access       = false
  plan.priority_support = false
  plan.archived         = false
  plan.features         = { 'projects' => true, 'tasks' => true }
end
puts "#{free_plan.name}"

basic_plan = Plan.find_or_create_by!(slug: 'basic') do |plan|
  plan.name             = 'Basic Plan'
  plan.price_cents      = 2_000
  plan.interval         = 'month'
  plan.max_projects     = 10
  plan.max_users        = 5
  plan.max_storage_mb   = 1_000
  plan.api_access       = false
  plan.priority_support = false
  plan.archived         = false
  plan.features         = { 'projects' => true, 'tasks' => true, 'reports' => true }
end
puts "#{basic_plan.name}"

pro_plan = Plan.find_or_create_by!(slug: 'pro') do |plan|
  plan.name             = 'Pro Plan'
  plan.price_cents      = 5_000
  plan.interval         = 'month'
  plan.max_projects     = nil
  plan.max_users        = nil
  plan.max_storage_mb   = nil
  plan.api_access       = true
  plan.priority_support = true
  plan.archived         = false
  plan.features         = { 'projects' => true, 'tasks' => true, 'reports' => true, 'api' => true }
end
puts "#{pro_plan.name}"

puts "Run 'rails stripe:setup_plans' to add Stripe Price IDs" if basic_plan.stripe_price_id.blank? || pro_plan.stripe_price_id.blank?
puts 'Creating users...'

owner = User.find_or_create_by!(email: 'owner@example.com') do |user|
  user.password              = 'password123'
  user.password_confirmation = 'password123'
  user.first_name            = 'John'
  user.last_name             = 'Owner'
end
puts "Owner: #{owner.email}"

admin = User.find_or_create_by!(email: 'admin@example.com') do |user|
  user.password              = 'password123'
  user.password_confirmation = 'password123'
  user.first_name            = 'Jane'
  user.last_name             = 'Admin'
end
puts "Admin: #{admin.email}"

member = User.find_or_create_by!(email: 'member@example.com') do |user|
  user.password              = 'password123'
  user.password_confirmation = 'password123'
  user.first_name            = 'Bob'
  user.last_name             = 'Member'
end
puts "Member: #{member.email}"

viewer = User.find_or_create_by!(email: 'viewer@example.com') do |user|
  user.password              = 'password123'
  user.password_confirmation = 'password123'
  user.first_name            = 'Alice'
  user.last_name             = 'Viewer'
end
puts "Viewer: #{viewer.email}"
puts 'Creating organizations...'

umbrella = Organization.find_or_create_by!(subdomain: 'umbrella') do |org|
  org.name = 'Umbrella Corporation'
end
puts "#{umbrella.name} (#{umbrella.subdomain}.localhost)"

some = Organization.find_or_create_by!(subdomain: 'some') do |org|
  org.name = 'Some Inc'
end
puts "#{some.name} (#{some.subdomain}.localhost)"
puts 'Creating memberships...'

[
  { user: owner, role: :owner },
  { user: admin, role: :admin },
  { user: member, role: :member },
  { user: viewer, role: :viewer }
].each do |membership_data|
  Membership.find_or_create_by!(user: membership_data[:user], organization: umbrella) do |membership|
    membership.role = membership_data[:role]
  end
end
puts "Umbrella: 4 members (owner, admin, member, viewer)"

Membership.find_or_create_by!(user: owner, organization: some) do |membership|
  membership.role = :owner
end
puts 'Some: 1 member (owner)'
puts 'Creating subscriptions...'

umbrella_sub = Subscription.find_or_create_by!(organization: umbrella) do |sub|
  sub.plan                 = free_plan
  sub.status               = :active
  sub.current_period_start = Time.current
end
puts "Umbrella: #{umbrella_sub.plan.name}"

some_sub = Subscription.find_or_create_by!(organization: some) do |sub|
  sub.plan = free_plan
  sub.status = :active
  sub.current_period_start = Time.current
end
puts "Some: #{some_sub.plan.name}"

if defined?(AdminUser)
  puts 'Creating ActiveAdmin user...'
  admin_user = AdminUser.find_or_create_by!(email: 'admin@example.com') do |au|
    au.password = 'password'
    au.password_confirmation = 'password'
  end
  puts "ActiveAdmin: #{admin_user.email} / password"
end

if Rails.env.development?
  puts 'Creating demo data...'

  ActsAsTenant.with_tenant(umbrella) do
    project1 = Project.find_or_create_by!(name: 'Website Redesign') do |p|
      p.description  = 'Complete redesign of company website'
      p.status       = :active
      p.organization = umbrella
    end
    puts "Project: #{project1.name}"

    project2 = Project.find_or_create_by!(name: 'Mobile App') do |p|
      p.description  = 'iOS and Android mobile application'
      p.status       = :active
      p.organization = umbrella
    end
    puts "Project: #{project2.name}"

    if defined?(Task)
      Task.find_or_create_by!(title: 'Design homepage mockup', project: project1) do |t|
        t.description = 'Create initial homepage design in Figma'
        t.status      = :todo
      end

      Task.find_or_create_by!(title: 'Setup development environment', project: project2) do |t|
        t.description = 'Configure React Native project'
        t.status      = :in_progress
      end

      puts 'Tasks: 2 created'
    end
  end
end

puts '=' * 80
puts 'Seeding complete!'
puts '=' * 80
