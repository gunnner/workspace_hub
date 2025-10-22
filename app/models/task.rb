class Task < ApplicationRecord
  include Task::RansackWhitelist

  acts_as_tenant(:organization)

  belongs_to :project
  belongs_to :organization

  enum :status, {
    todo:        0,
    in_progress: 1,
    completed:   2
  }.freeze

  validates :title, presence: true

  before_validation :set_organization_from_project, on: :create

  private

  def set_organization_from_project
    self.organization ||= project&.organization
  end
end
