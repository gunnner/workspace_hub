class Subscription < ApplicationRecord
  belongs_to :organization
  belongs_to :plan

  enum :status, {
    trialing:           0,
    active:             1,
    past_due:           2,
    canceled:           3,
    unpaid:             4,
    incomplete:         5,
    incomplete_expired: 6
  }.freeze

  validates :status, presence: true
  validates :organization_id, uniqueness: true
  validate  :only_one_active_subscription, on: :create


  scope :active_or_trialing,   -> { where(status: %i[active trialing]) }
  scope :active_subscriptions, -> { where(status: %i[active trialing]) }
  scope :expiring_soon,        -> { where('current_period_end < ?', 7.days.from_now) }
  scope :churned,              -> { where(status: :canceled) }
  scope :revenue_generating,   -> { joins(:plan).where('plans.price_cents > 0').where(status: %i[active trialing]) }
  scope :by_plan, ->(plan) { where(plan: plan) }

  before_validation :set_trial_period,   on: :create, unless: :stripe_subscription_id
  before_validation :set_billing_period, on: :create, unless: :stripe_subscription_id

  def stripe_subscription
    return nil unless stripe_subscription_id

    @stripe_subscription ||= Stripe::Subscription.retrieve(stripe_subscription_id)
  rescue Stripe::StripeError => e
    Rails.logger.error("Failed to retrieve Stripe subscription: #{e.message}")
    nil
  end

  def stripe_customer
    return nil unless stripe_customer_id

    @stripe_customer ||= Stripe::Customer.retrieve(stripe_customer_id)
  rescue Stripe::StripeError => e
    Rails.logger.error("Failed to retrieve Stripe customer: #{e.message}")
    nil
  end

  def on_trial?
    trialing? && trial_ends_at.present? && trial_ends_at > Time.current
  end

  def trial_ended?
    trial_ends_at.present? && trial_ends_at <= Time.current
  end

  def trial_days_remaining
    return 0 unless on_trial?

    calculate_remaining_days(trial_ends_at)
  end

  def active_subscription?
    active? || on_trial?
  end

  def can_access?
    active_subscription? && !past_due?
  end

  def past_due?
    super && current_period_end.present? && current_period_end < Time.current
  end

  def days_until_renewal
    return 0 unless current_period_end.present?

    calculate_remaining_days(current_period_end)
  end

  def calculate_remaining_days(period_end)
    ((period_end - Time.current) / 1.day).ceil
  end

  def within_project_limit?(current_count)
    plan.unlimited_projects? || current_count < plan.max_projects
  end

  def within_user_limit?(current_count)
    plan.unlimited_users? || current_count < plan.max_users
  end

  def can_create_project?
    return false unless active_subscription?

    within_project_limit?(organization.projects_count)
  end

  def can_invite_user?
    return false unless active_subscription?

    within_user_limit?(organization.user_count)
  end

  def cancel!(reason: nil)
    update!(
      status: :canceled,
      canceled_at: Time.current,
      cancellation_reason: reason
    )
  end

  def reactivate!
    return false unless can_reactivate?

    update!(
      status: :active,
      canceled_at: nil,
      cancellation_reason: nil,
      current_period_end: calculate_period_end
    )
  end

  def can_reactivate?
    canceled? && canceled_at.present? && current_period_end > Time.current
  end

  def cancel_at_end_of_period!
    return false unless stripe_subscription_id

    stripe_sub = Stripe::Subscription.update(stripe_subscription_id, cancel_at_period_end: true)
    update!(cancel_at_period_end: true)
    stripe_sub
  rescue Stripe::StripeError => e
    Rails.logger.error("Failed to cancel subscription: #{e.message}")
    false
  end

  def reactivate_stripe!
    return false unless stripe_subscription_id && cancel_at_period_end?

    stripe_sub = Stripe::Subscription.update(stripe_subscription_id, cancel_at_period_end: false)
    update!(cancel_at_period_end: false)
    stripe_sub
  rescue Stripe::StripeError => e
    Rails.logger.error("Failed to reactivate subscription: #{e.message}")
    false
  end

  private

  def only_one_active_subscription
    return unless organization.present?
    return if organization.subscription.nil?
    return if organization.subscription.id.eql?(id)

    errors.add(:base, 'Organization already has a subscription') if organization.subscription.persisted? && organization.subscription.id != id
  end

  def set_trial_period
    return if plan.nil? || plan.free? || trial_ends_at.present?

    self.status = :trialing
    self.trial_ends_at = 14.days.from_now
  end

  def set_billing_period
    return if plan.nil?

    self.current_period_start ||= Time.current
    self.current_period_end   ||= calculate_period_end
  end

  def calculate_period_end
    return nil if plan.free?

    plan.monthly? ? 1.month.from_now
                  : 1.year.from_now
  end
end
