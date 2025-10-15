# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "Seeding #{Rails.env} environment..."

# Load environment-specific seeds
seeds_file = Rails.root.join('db', 'seeds', "#{Rails.env}.rb")
if File.exist?(seeds_file)
  load seeds_file
else
  puts 'Loading default data...'
  puts 'Creating plans...'

  Plan.destroy_all

  [
    {
      name: 'Free Plan',
      slug: 'free',
      price_cents: 0,
      interval: 'month',
      max_projects: 3,
      max_users: 1,
      max_storage_mb: 100,
      api_access: false,
      priority_support: false,
      archived: false,
      features: { 'projects' => true, 'tasks' => true }
    },
    {
      name: 'Basic Plan',
      slug: 'basic',
      price_cents: 2_000,
      interval: 'month',
      max_projects: 10,
      max_users: 5,
      max_storage_mb: 1_000,
      api_access: false,
      priority_support: false,
      archived: false,
      features: { 'projects' => true, 'tasks' => true, 'reports' => true }
    },
    {
      name: 'Pro Plan',
      slug: 'pro',
      price_cents: 5_000,
      interval: 'month',
      max_projects: nil,
      max_users: nil,
      max_storage_mb: 10_000,
      api_access: true,
      priority_support: true,
      archived: false,
      features: {
        'projects' => true,
        'tasks' => true,
        'reports' => true,
        'api_access' => true,
        'webhooks' => true
      }
    }
  ].each do |plan_data|
    Plan.create!(plan_data)
    puts "#{plan_data[:name]}"
  end

  puts 'Creating users and organizations...'

  owner = User.create!(
    email: 'owner@example.com',
    password: 'password123',
    password_confirmation: 'password123',
    first_name: 'John',
    last_name: 'Owner'
  )
  puts "Owner: #{owner.email}"

  admin = User.create!(
    email: 'admin@example.com',
    password: 'password123',
    password_confirmation: 'password123',
    first_name: 'Jane',
    last_name: 'Admin'
  )
  puts "Admin: #{admin.email}"

  member = User.create!(
    email: 'member@example.com',
    password: 'password123',
    password_confirmation: 'password123',
    first_name: 'Bob',
    last_name: 'Member'
  )
  puts "Member: #{member.email}"

  viewer = User.create!(
    email: 'viewer@example.com',
    password: 'password123',
    password_confirmation: 'password123',
    first_name: 'Alice',
    last_name: 'Viewer'
  )
  puts "Viewer: #{viewer.email}"

  # Organization
  org = Organization.create!(
    name: 'Umbrella Corporation',
    subdomain: 'umbrella'
  )
  puts "Organization: #{org.name}"

  # Memberships
  Membership.create!(user: owner, organization: org, role: :owner)
  Membership.create!(user: admin, organization: org, role: :admin)
  Membership.create!(user: member, organization: org, role: :member)
  Membership.create!(user: viewer, organization: org, role: :viewer)
  puts "Created 4 memberships"

  puts "Seeded #{Plan.count} plans, #{User.count} users, #{Organization.count} organizations"
end
