class BillingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization
  before_action :authorize_billing_access

  # GET /billing
  def show
    @subscription = @organization.subscription
    @plan = @subscription&.plan
    @available_plans = Plan.active.order(:price_cents)
  end

  # POST /billing/checkout
  def checkout
    plan = Plan.find(params[:plan_id])

    if plan.free?
      flash[:error] = 'Free plan does not require checkout'
      redirect_to billing_path and return
    end

    customer = find_or_create_stripe_customer
    session = Stripe::Checkout::Session.create(
      customer: customer.id,
      payment_method_types: [ 'card' ],
      line_items: [
        {
          price: plan.stripe_price_id,
          quantity: 1
        }
      ],
      mode: 'subscription',
      success_url: success_billing_url,
      cancel_url: billing_url,
      metadata: {
        organization_id: @organization.id,
        plan_id: plan.id
      },
      subscription_data: {
        metadata: {
          organization_id: @organization.id,
          plan_id: plan.id
        }
      }
    )

    redirect_to session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    Rails.logger.error("Stripe checkout error: #{e.message}")
    flash[:error] = "Payment error: #{e.message}"
    redirect_to billing_path
  end

  # GET /billing/success
  def success
    flash[:notice] = 'Subscription created successfully! It may take a few moments to activate.'
    redirect_to billing_path
  end

  # GET /billing/portal
  def portal
    customer = find_or_create_stripe_customer
    portal_session = Stripe::BillingPortal::Session.create(customer: customer.id, return_url: billing_url)
    redirect_to portal_session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    Rails.logger.error("Stripe portal error: #{e.message}")
    flash[:error] = "Portal error: #{e.message}"
    redirect_to billing_path
  end

  private

  def set_organization
    @organization = current_organization
  end

  def authorize_billing_access
    unless current_user.can_manage_billing_for?(@organization)
      flash[:error] = 'Only organization owners can manage billing'
      redirect_to new_user_session_path
    end
  end

  def find_or_create_stripe_customer
    subscription = @organization.subscription
    return Stripe::Customer.retrieve(subscription.stripe_customer_id) if subscription&.stripe_customer_id

    customer = Stripe::Customer.create(
      email: current_user.email,
      name: @organization.name,
      metadata: {
        organization_id: @organization.id,
        user_id: current_user.id
      }
    )

    subscription ||= @organization.build_subscription(
      plan: Plan.find_by(slug: 'free'),
      status: :active
    )
    subscription.update!(stripe_customer_id: customer.id)

    customer
  end
end
