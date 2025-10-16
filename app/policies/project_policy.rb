class ProjectPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope
    end
  end

  def index?
    user_membership.present?
  end

  def show?
    user_membership.present?
  end

  def create?
    user_membership&.can_create_projects?
  end

  def new?
    create?
  end

  def update?
    return true if user_membership&.owner? || user_membership&.admin?

    user_membership&.can_edit_project?(record)
  end

  def edit?
    update?
  end

  def destroy?
    return true if user_membership&.owner? || user_membership&.admin?

    user_membership&.can_delete_project?(record)
  end

  private

  def user_membership
    @user_membership ||= user.memberships.find_by(organization: record.organization)
  end
end
