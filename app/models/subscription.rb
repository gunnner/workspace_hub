class Subscription < ApplicationRecord
  belongs_to :organization
  belongs_to :plan

  enum :status, {
    trialing: 0,
    active:   1,
    past_due: 2,
    canceled: 3,
    unpaid:   4
  }.freeze

  validates :organization, presence: true
  validates :plan,         presence: true
  validates :status,       presence: true

  scope :active_or_trialing, -> { where(status: %i[active trialing]) }
  scope :expiring_soon, -> { where('current_period_end < ?', 7.days.from_now) }

  before_create :set_trial_period, if: :plan_has_trial?
  before_create :set_billing_period

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

  def days_until_renewal
    return 0 unless current_period_end.present?

    calculate_remaining_days(current_period_end)
  end

  def calculate_remaining_days(period_end)
    ((period_end - Time.current) / 1.day).ceil
  end

  def cancel!(reason: nil)
    update!(
      status: :canceled,
      canceled_at: Time.current,
      cancellation_reason: reason
    )
  end

  def reactivate!
    return false if canceled_at.blank?

    update!(
      status: :active,
      canceled_at: nil,
      cancellation_reason: nil
    )
  end

  def withing_projects_limits?(current_count)
    plan.unlimited_projects? || current_count < plan.max_projects
  end

  def within_users_limits?(current_count)
    plan.unlimited_users? || current_count < plan.max_users
  end

  def can_create_project?
    withing_projects_limits?(organization.projects.count)
  end

  def can_invite_users?
    within_users_limits?(organization.user.count)
  end

  private

  def plan_has_trial?
    !plan.free?
  end

  def set_trial_period
    self.status = :trialing
    self.trial_ends_at = 14.days.from_now
  end

  def set_billing_period
    self.current_period_start ||= Time.current
    self.current_period_end   ||= define_billing_period_end
  end

  def define_billing_period_end
    plan.monthly? ? 1.month.from_now
                  : 1.year.from_now
  end
end
