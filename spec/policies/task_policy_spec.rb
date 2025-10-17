require 'rails_helper'

RSpec.describe TaskPolicy, type: :policy do
  subject { described_class }

  let(:organization) { create(:organization) }
  let(:project)      { create(:project, organization: organization) }
  let(:task)         { create(:task, project: project) }

  context 'for an owner' do
    let(:user) { create(:user) }

    before do
      create(:membership, user: user, organization: organization, role: :owner)
    end

    permissions :index?, :show?, :create?, :update?, :destroy? do
      it 'grants access' do
        expect(subject).to permit(user, task)
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
        expect(subject).to permit(user, task)
      end
    end
  end

  context 'for a member' do
    let(:user) { create(:user) }

    before do
      create(:membership, user: user, organization: organization, role: :member)
    end

    permissions :index?, :show?, :create?, :update?, :destroy? do
      it 'grants access' do
        expect(subject).to permit(user, task)
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
        expect(subject).to permit(user, task)
      end
    end

    permissions :create?, :update?, :destroy? do
      it 'denies access' do
        expect(subject).not_to permit(user, task)
      end
    end
  end

  describe 'Scope' do
    let(:user) { create(:user) }
    let(:org1) { create(:organization) }
    let(:org2) { create(:organization) }

    before do
      Task.delete_all
      create(:membership, user: user, organization: org1, role: :member)
      ActsAsTenant.current_tenant = org1
    end

    it 'returns only tasks from user organizations' do
      project1 = create(:project, organization: org1)
      project2 = ActsAsTenant.with_tenant(org2) do
        create(:project, organization: org2)
      end

      task1 = create(:task, project: project1)
      task2 = ActsAsTenant.with_tenant(org2) do
        create(:task, project: project2)
      end

      resolved = Pundit.policy_scope(user, Task)

      expect(resolved.pluck(:id)).to eq([ task1.id ])
    end
  end
end
