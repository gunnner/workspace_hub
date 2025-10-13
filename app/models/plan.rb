class Plan < ApplicationRecord
  has_many :subscriptions
  has_many :organizations, through: :subscriptions

  validates :name,        presence: true
  validates :slug,        presence: true, uniqueness: true
  validates :price_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :interval,    presence: true, inclusion:    { in: %w[month year] }

  scope :active,   -> { where(archived: false) }
  scope :by_price, -> { order(price_cents: :asc) }

  def price
    Money.new(price_cents, 'USD')
  end

  def price=(amount)
    self.price_cents =(amount.to_f * 100).to_i
  end

  def free?
    price_cents.zero?
  end

  def monthly?
    interval.eql?('month')
  end

  def yearly?
    interval.eql?('year')
  end

  def feature_enabled?(feature_name)
    features[feature_name.to_s].eql?(true)
  end

  def unlimited_projects?
    max_projects.nil?
  end

  def unlimited_users?
    max_users.nil?
  end
end
