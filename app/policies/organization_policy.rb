class OrganizationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:memberships).where(memberships: { user_id: user.id })
    end
  end

  def show?
    user_membership.present?
  end

  def update?
    user_membership&.owner? || user_membership&.admin?
  end

  def destroy?
    user_membership&.owner?
  end

  def manage_members?
    user_membership&.can_manage_members?
  end

  def manage_billing?
    user_membership&.can_manage_billing?
  end

  def change_subscription?
    user_membership&.owner?
  end

  private

  def user_membership
    @user_membership ||= user.memberships.find_by(organization: record)
  end
end
