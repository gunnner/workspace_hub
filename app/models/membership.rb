class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  enum role: {
    member: 0,
    admin:  1,
    owner:  2
  }.freeze

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :organization_id }
end
