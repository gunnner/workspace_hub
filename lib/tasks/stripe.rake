namespace :stripe do
  desc 'Setup all Stripe plans (create products, prices, and database records)'
  task setup_plans: :environment do
    puts 'Setting up Stripe plans...'

    paid_plans_data = [
      {
        name: 'Basic Plan',
        slug: 'basic',
        price_cents: 2_000, # $20.00
        interval: 'month',
        max_projects: 10,
        max_users: 5,
        max_storage_mb: 1_000,
        api_access: false,
        priority_support: false,
        features: { 'projects' => true, 'tasks' => true, 'reports' => true }
      },
      {
        name: 'Pro Plan',
        slug: 'pro',
        price_cents: 5_000, # $50.00
        interval: 'month',
        max_projects: -1, # unlimited
        max_users: -1, # unlimited
        max_storage_mb: 10_000,
        api_access: true,
        priority_support: true,
        features: {
          'projects' => true,
          'tasks' => true,
          'reports' => true,
          'api_access' => true,
          'webhooks' => true
        }
      }
    ]

    paid_plans_data.each do |plan_data|
      puts "Processing: #{plan_data[:name]}"

      begin
        existing_plan = Plan.find_by(slug: plan_data[:slug])
        if existing_plan
          puts 'Plan exists in database'
          if existing_plan.stripe_price_id.present?
            puts "Stripe Price ID already set: #{existing_plan.stripe_price_id}"
            next
          else
            puts 'Creating Stripe product and price...'
          end
        end

        product = Stripe::Product.create(
          name:        plan_data[:name],
          description: "#{plan_data[:name]} - Professional workspace management",
          metadata: {
            slug:         plan_data[:slug],
            max_projects: plan_data[:max_projects],
            max_users:    plan_data[:max_users]
          }
        )
        puts "Stripe Product created: #{product.id}"

        price = Stripe::Price.create(
          product:     product.id,
          unit_amount: plan_data[:price_cents],
          currency:    'usd',
          recurring: {
            interval: plan_data[:interval]
          },
          metadata: {
            slug: plan_data[:slug]
          }
        )
        puts "Stripe Price created: #{price.id} ($#{plan_data[:price_cents] / 100.0}/#{plan_data[:interval]})"

        if existing_plan
          existing_plan.update!(stripe_price_id: price.id)
          puts 'Updated plan with Stripe Price ID'
        else
          Plan.create!(plan_data.merge(stripe_price_id: price.id, archived: false))
          puts 'Created plan in database'
        end
      rescue Stripe::StripeError => e
        puts "Stripe Error: #{e.message}"
      rescue ActiveRecord::RecordInvalid => e
        puts "Database Error: #{e.message}"
        puts "#{e.record.errors.full_messages.join(', ')}"
      end
    end

    puts 'Stripe setup complete!'
    puts 'Plans Summary:'
    puts '=' * 80

    Plan.order(:price_cents).each do |plan|
      stripe_status = plan.stripe_price_id.present? ? "Stripe: #{plan.stripe_price_id}" : 'No Stripe (Free plan)'
      puts "#{plan.name} | $#{plan.price_in_dollars} | #{stripe_status}"
    end
    puts '=' * 80
  end

  desc 'List all Stripe products and prices'
  task list_products: :environment do
    puts 'Stripe Products & Prices:'
    puts '=' * 80

    products = Stripe::Product.list(limit: 100, active: true)
    if products.data.blank?
      puts 'No products found in Stripe.'
      puts "Run 'rails stripe:setup_plans' to create them."
    else
      products.each do |product|
        puts "#{product.name}"
        puts "Product ID: #{product.id}"
        puts "Description: #{product.description}" if product&.description

        prices = Stripe::Price.list(product: product.id, active: true)
        prices.each do |price|
          amount = price.unit_amount / 100.0
          puts "Price: $#{amount}/#{price}"
          puts "Price ID: #{price.id}"
        end
      end
    end

    puts '=' * 80
  end
end
