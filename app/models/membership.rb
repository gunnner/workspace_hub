class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  enum :role, {
    owner:  0,  # full access + billing
    admin:  1,  # manage users, projects, tasks (without billing)
    member: 2,  # create/update projects and tasks
    viewer: 3   # only view
  }.freeze

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :organization_id, message: 'already belongs to this organization' }

  scope :owners,     -> { where(role: :owner) }
  scope :admins,     -> { where(role: :admin) }
  scope :members,    -> { where(role: :member) }
  scope :viewers,    -> { where(role: :viewer) }
  scope :can_manage, -> { where(role: %i[owner admin]) }

  def can_manage_members?
    owner? || admin?
  end

  def can_manage_billing?
    owner?
  end

  def can_create_projects?
    owner? || admin? || member?
  end

  def can_view_projects?
    true
  end

  def can_edit_project?(project)
    return true if owner? || admin?
    return true if member? && project.created_by_id.eql?(user_id)

    false
  end

  def can_delete_project?(project)
    return true if owner? || admin?
    return true if member? && project.created_by_id.eql?(user_id)

    false
  end

  def can_create_tasks?
    owner? || admin? || member?
  end

  def can_edit_task?(task)
    return true if owner? || admin? || member?

    false
  end
end
