class StripeWebhooksController < ActionController::API
  def create
    payload         = request.body.read
    sig_header      = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = Rails.configuration.stripe[:webhook_secret]

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError => e
      Rails.logger.error("Webhook JSON parse error: #{e.message}")
      render json: { error: 'Invalid payload' }, status: 400
      return
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error("Webhook signature verification failed: #{e.message}")
      render json: { error: 'Invalid signature' }, status: 400
      return
    end

    Rails.logger.info("Webhook received: #{event.type}")

    handle_stripe_event(event)
    render json: { status: 'success' }, status: 200
  end

  private

  def handle_stripe_event(event)
    case event.type.to_s
    when 'checkout.session.completed'
      handle_checkout_completed(event.data.object)
    when 'customer.subscription.updated'
      handle_subscription_updated(event.data.object)
    when 'customer.subscription.deleted'
      handle_subscription_deleted(event.data.object)
    when 'invoice.payment_succeeded'
      handle_payment_succeeded(event.data.object)
    when 'invoice.payment_failed'
      handle_payment_failed(event.data.object)
    else
      Rails.logger.info("Unhandled event type: #{event.type}")
    end
  end

  def handle_checkout_completed(session)
    Rails.logger.info('Processing checkout.session.completed')

    unless session.subscription
      Rails.logger.warn('No subscription in session - likely a one-time payment')
      return
    end

    unless session.metadata&.organization_id && session.metadata&.plan_id
      Rails.logger.error('Missing metadata in session')
      Rails.logger.error("Available metadata: #{session.metadata.to_hash}")
      return
    end

    subscription_data = Stripe::Subscription.retrieve(session.subscription)
    organization_id   = session.metadata.organization_id
    plan_id           = session.metadata.plan_id

    organization      = Organization.find(organization_id)
    plan              = Plan.find(plan_id)

    subscription      = organization.subscription || organization.build_subscription
    subscription_item = subscription_data.items.data.first

    subscription.update!(
      plan:                   plan,
      stripe_subscription_id: subscription_data.id,
      stripe_customer_id:     subscription_data.customer,
      status:                 map_stripe_status(subscription_data.status),
      current_period_start:   Time.at(subscription_item.current_period_start),
      current_period_end:     Time.at(subscription_item.current_period_end),
      trial_ends_at:          subscription_data.trial_end ? Time.at(subscription_data.trial_end) : nil
    )

    UserMailer.payment_success_email(organization).deliver_later

    Rails.logger.info("Subscription created for organization #{organization_id}")
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error("Record not found: #{e.message}")
  rescue Stripe::StripeError => e
    Rails.logger.error("Stripe error: #{e.message}")
  rescue StandardError => e
    Rails.logger.error("Error: #{e.class} - #{e.message}")
    Rails.logger.error("Subscription data: #{subscription_data.inspect}") if defined?(subscription_data)
    Rails.logger.error(e.backtrace.first(10).join("\n"))
  end

  def handle_subscription_updated(subscription_data)
    subscription = Subscription.find_by(stripe_subscription_id: subscription_data.id)

    unless subscription
      Rails.logger.warn("Subscription not found: #{subscription_data.id}")
      return
    end

    subscription_item = subscription_data.items.data.first
    subscription.update!(
      status:               map_stripe_status(subscription_data.status),
      current_period_start: Time.at(subscription_item.current_period_start),
      current_period_end:   Time.at(subscription_item.current_period_end),
      cancel_at_period_end: subscription_data.cancel_at_period_end
    )

    Rails.logger.info("Subscription updated: #{subscription.id}")
  rescue StandardError => e
    Rails.logger.error("Error in subscription.updated: #{e.message}")
  end

  def handle_subscription_deleted(subscription_data)
    subscription = Subscription.find_by(stripe_subscription_id: subscription_data.id)

    unless subscription
      Rails.logger.warn("Subscription not found: #{subscription_data.id}")
      return
    end

    organization = subscription.organization
    subscription.update!(status: :canceled, canceled_at: Time.current)
    UserMailer.subscription_canceled_email(organization).deliver_later

    Rails.logger.info("Subscription canceled: #{subscription.id}")
  rescue StandardError => e
    Rails.logger.error("Error in subscription.deleted: #{e.message}")
  end

  def handle_payment_succeeded(invoice)
    subscription = Subscription.find_by(stripe_customer_id: invoice.customer)

    unless subscription
      Rails.logger.warn("Subscription not found for customer: #{invoice.customer}")
      return
    end

    organization = subscription.organization
    UserMailer.subscription_renewed_email(organization).deliver_later

    Rails.logger.info("Payment succeeded for subscription: #{subscription.id}")
  rescue StandardError => e
    Rails.logger.error("Error in payment.succeeded: #{e.message}")
  end

  def handle_payment_failed(invoice)
    subscription = Subscription.find_by(stripe_customer_id: invoice.customer)

    unless subscription
      Rails.logger.warn("Subscription not found for customer: #{invoice.customer}")
      return
    end

    organization = subscription.organization
    subscription.update!(status: :past_due)
    UserMailer.payment_failed_email(organization).deliver_later

    Rails.logger.warn("Payment failed for subscription: #{subscription.id}")
  rescue StandardError => e
    Rails.logger.error("Error in payment.failed: #{e.message}")
  end

  def map_stripe_status(stripe_status)
    case stripe_status
    when 'active'             then :active
    when 'trialing'           then :trialing
    when 'past_due'           then :past_due
    when 'canceled'           then :canceled
    when 'incomplete'         then :incomplete
    when 'incomplete_expired' then :incomplete_expired
    when 'unpaid'             then :unpaid
    else :incomplete
    end
  end
end
