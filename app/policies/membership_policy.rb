class MembershipPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:organization).where(organizations: { id: user.organization_ids })
    end
  end

  def index?
    organization_membership.present?
  end

  def show?
    organization_membership.present?
  end

  def create?
    organization_membership&.can_manage_members?
  end

  def update?
    return false if record.user_id.eql?(user.id)

    organization_membership&.can_manage_members?
  end

  def destroy?
    return false if record.user_id.eql?(user.id)

    organization_membership&.can_manage_members?
  end

  private

  def organization_membership
    @organization_membership ||= user.memberships.find_by(organization: record.organization)
  end
end
