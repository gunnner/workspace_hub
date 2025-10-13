class Organization < ApplicationRecord
  RESERVED_SUBDOMAINS = %w[
    www admin api app blog help support mail ftp webmail localhost staging production test development docs status dashboard
  ].freeze

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_one :subscription, dependent: :destroy
  has_one :plan, through: :subscription

  delegate :on_trial?, :trial_days_remaining, :can_create_project?, :can_invite_user?, to: :subscription, allow_nil: false

  validates :name, presence: true
  validates :subdomain, presence: true,
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

  def projects
    ActsAsTenant.with_tenant(self) do
      Project.all
    end
  end

  private

  def normalize_subdomain
    self.subdomain = subdomain.to_s.downcase.strip
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
end
