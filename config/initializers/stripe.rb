if Rails.env.production?
  Rails.configuration.stripe = {
    publishable_key: Rails.application.credentials.dig(:stripe, :publishable_key),
    secret_key:      Rails.application.credentials.dig(:stripe, :secret_key),
    webhook_secret:  Rails.application.credentials.dig(:stripe, :webhook_secret)
  }
else
  Rails.configuration.stripe = {
    publishable_key: ENV['STRIPE_PUBLISHABLE_KEY'],
    secret_key:      ENV['STRIPE_SECRET_KEY'],
    webhook_secret:  ENV['STRIPE_WEBHOOK_SECRET']
  }
end

Stripe.api_key     = Rails.configuration.stripe[:secret_key]
Stripe.api_version = ENV['STRIPE_API_VERSION']

Rails.logger.info "Stripe initialized with #{Rails.env} keys"
