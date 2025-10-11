class Organization < ApplicationRecord
  RESERVED_SUBDOMAINS = %w[
    www admin api app blog help support mail ftp webmail localhost staging production test development docs status dashboard
  ].freeze

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships

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

  private

  def normalize_subdomain
    self.subdomain = subdomain.to_s.downcase.strip
  end
end
