require 'rails_helper'

RSpec.describe ProjectPolicy, type: :policy do
  subject { described_class }

  let(:organization) { create(:organization) }
  let(:project) { create(:project, organization: organization) }

  context 'for a visitor (no user)' do
    let(:user) { nil }

    permissions :index?, :show?, :create?, :update?, :destroy? do
      it 'denies access' do
        expect(subject).not_to permit(user, project)
      end
    end
  end

  context 'for an owner' do
    let(:user) { create(:user) }

    before do
      create(:membership, user: user, organization: organization, role: :owner)
    end

    permissions :index?, :show? do
      it 'grants access' do
        expect(subject).to permit(user, project)
      end
    end

    permissions :create?, :update?, :destroy? do
      it 'grants access' do
        expect(subject).to permit(user, project)
      end
    end
  end

  context 'for an admin' do
    let(:user) { create(:user) }

    before do
      create(:membership, user: user, organization: organization, role: :admin)
    end

    permissions :index?, :show?, :create?, :update?, :destroy? do
      it 'grants access' do
        expect(subject).to permit(user, project)
      end
    end
  end

  context 'for a member' do
    let(:user)       { create(:user) }
    let(:other_user) { create(:user) }

    before do
      create(:membership, user: user, organization: organization, role: :member)
      create(:membership, user: other_user, organization: organization, role: :member)
    end

    permissions :index?, :show?, :create? do
      it 'grants access' do
        expect(subject).to permit(user, project)
      end
    end

    context 'for own project' do
      let(:project) { create(:project, organization: organization, created_by: user) }

      permissions :update?, :destroy? do
        it 'grants access' do
          expect(subject).to permit(user, project)
        end
      end
    end

    context 'for other member project' do
      let(:project) { create(:project, organization: organization, created_by: other_user) }

      permissions :update?, :destroy? do
        it 'denies access' do
          expect(subject).not_to permit(user, project)
        end
      end
    end
  end

  context 'for a viewer' do
    let(:user) { create(:user) }

    before do
      create(:membership, user: user, organization: organization, role: :viewer)
    end

    permissions :index?, :show? do
      it 'grants access' do
        expect(subject).to permit(user, project)
      end
    end

    permissions :create?, :update?, :destroy? do
      it 'denies access' do
        expect(subject).not_to permit(user, project)
      end
    end
  end

  context 'for user from different organization' do
    let(:user)      { create(:user) }
    let(:other_org) { create(:organization) }

    before do
      create(:membership, user: user, organization: other_org, role: :owner)
    end

    permissions :index?, :show?, :create?, :update?, :destroy? do
      it 'denies access' do
        expect(subject).not_to permit(user, project)
      end
    end
  end

  describe 'Scope' do
    let(:user) { create(:user) }
    let(:org1) { create(:organization) }
    let(:org2) { create(:organization) }

    before do
      Project.delete_all
      create(:membership, user: user, organization: org1, role: :member)
      ActsAsTenant.current_tenant = org1
    end

    it 'returns only projects from user organizations' do
      project1 = create(:project, organization: org1)
      project2 = ActsAsTenant.with_tenant(org2) do
        create(:project, organization: org2)
      end
      project3 = create(:project, organization: org1)

      resolved = Pundit.policy_scope(user, Project)

      expect(resolved.pluck(:id)).to contain_exactly(project1.id, project3.id)
    end
  end
end
