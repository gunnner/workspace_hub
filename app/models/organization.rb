class Organization < ApplicationRecord
  include Organization::RansackWhitelist

  RESERVED_SUBDOMAINS = %w[
    www admin api app blog help support mail ftp webmail localhost staging production test development docs status dashboard
  ].freeze
  FREE_PLAN_SLUG = 'free'.freeze

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :projects, dependent: :destroy
  has_one :subscription, dependent: :destroy
  has_one :plan, through: :subscription

  validates :name, presence: true
  validates :subdomain,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: {
              with: /\A[a-z0-9-]+\z/,
              message: 'only allows lowercase letters, numbers and dashes'
            },
            exclusion: {
              in: RESERVED_SUBDOMAINS,
              message: '%{value} is reserved'
            }

  before_validation :normalize_subdomain
  after_create :create_free_subscription, unless: :subscription_exists?


  def on_trial?
    subscription&.on_trial? || false
  end

  def trial_days_remaining
    subscription&.trial_days_remaining || 0
  end

  def can_create_project?
    return false unless subscription

    subscription.can_create_project?
  end

  def can_invite_user?
    return false unless subscription

    subscription.can_invite_user?
  end

  def subscribed?
    subscription.present? && subscription.active_subscription?
  end

  def free_plan?
    plan&.free? || subscription.nil?
  end

  def can_access_feature?(feature_name)
    return false unless subscribed?

    plan.feature_enabled?(feature_name)
  end

  def projects
    ActsAsTenant.with_tenant(self) do
      Project.all
    end
  end

  def projects_count
    projects.count
  end

  def add_user(user, role: :member)
    memberships.create!(user: user, role: role)
  end

  def remove_user(user)
    memberships.find_by(user: user)&.destroy
  end

  def owners
    user.joins(:memberships).where(memberships: { role: :owner })
  end

  def admins
    users.joins(:memberships).where(memberships: { role: :admin })
  end

  def members
    users.joins(:memberships).where(memberships: { role: :member })
  end

  def viewers
    users.joins(:memberships).where(memberships: { role: :viewer })
  end

  def can_add_user?
    return true if subscription.nil?

    subscription.can_invite_user?
  end

  def user_count
    users.count
  end

  private

  def normalize_subdomain
    self.subdomain = subdomain.to_s.downcase.strip
  end

  def subscription_exists?
    subscription.present?
  end

  def create_free_subscription
    free_plan = Plan.active.find_by(slug: FREE_PLAN_SLUG)
    raise StandardError, "Free plan (#{FREE_PLAN_SLUG}) not found!" unless free_plan

    create_subscription!(plan: free_plan, status: :active, current_period_start: Time.current)
  rescue ActiveRecord::RecordInvalid => e
    raise e
  end
end
