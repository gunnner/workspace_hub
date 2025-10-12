class Project < ApplicationRecord
  acts_as_tenant(:organization)

  belongs_to :organization, optional: false
  has_many   :tasks, dependent: :destroy

  enum :status, {
    active:    0,
    archived:  1,
    completed: 2
  }.freeze

  validates :name, presence: true

  scope :active, -> { where(status: :active) }
  scope :recent, -> { order(created_at: :desc) }
end
