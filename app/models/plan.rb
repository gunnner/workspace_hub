class Plan < ApplicationRecord
  include Plan::RansackWhitelist

  has_many :subscriptions, dependent: :restrict_with_error
  has_many :organizations, through: :subscriptions

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :interval, presence: true, inclusion: { in: %w[month year] }

  scope :active,     -> { where(archived: false) }
  scope :archived,   -> { where(archived: true) }
  scope :by_price,   -> { order(price_cents: :asc) }
  scope :free_plans, -> { where(price_cents: 0) }
  scope :paid_plans, -> { where('price_cents > 0') }

  def price_in_dollars
    price_cents / 100.0
  end
  def display_price
    return 'Free' if free?

    "$#{price_in_dollars.to_i}/#{interval}"
  end

  def free?
    price_cents.zero?
  end

  def paid?
    !free?
  end

  def requires_stripe?
    paid?
  end

  def monthly?
    interval.to_s.eql?('month')
  end

  def yearly?
    interval.to_s.eql?('year')
  end

  def archive!
    raise 'Cannot archive plan with active subscriptions' if has_active_subscriptions?
    update!(archived: true)
  end

  def unarchive!
    update!(archived: false)
  end

  def can_archive?
    !has_active_subscriptions?
  end

  def has_active_subscriptions?
    subscriptions.active_or_trialing.exists?
  end

  def feature_enabled?(feature_name)
    features.is_a?(Hash) && features[feature_name.to_s].eql?(true)
  end

  def unlimited_projects?
    max_projects.eql?(-1) || max_projects.nil?
  end

  def unlimited_users?
    max_users.eql?(-1) || max_users.nil?
  end
end
