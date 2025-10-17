require 'rails_helper'

RSpec.describe OrganizationPolicy, type: :policy do
  subject { described_class }

  let(:organization) { create(:organization) }

  context 'for an owner' do
    let(:user) { create(:user) }

    before do
      create(:membership, user: user, organization: organization, role: :owner)
    end

    permissions :show?, :update?, :destroy?, :manage_members?, :manage_billing?, :change_subscription? do
      it 'grants access' do
        expect(subject).to permit(user, organization)
      end
    end
  end

  context 'for an admin' do
    let(:user) { create(:user) }

    before do
      create(:membership, user: user, organization: organization, role: :admin)
    end

    permissions :show?, :update?, :manage_members? do
      it 'grants access' do
        expect(subject).to permit(user, organization)
      end
    end

    permissions :destroy?, :manage_billing?, :change_subscription? do
      it 'denies access' do
        expect(subject).not_to permit(user, organization)
      end
    end
  end

  context 'for a member' do
    let(:user) { create(:user) }

    before do
      create(:membership, user: user, organization: organization, role: :member)
    end

    permissions :show? do
      it 'grants access' do
        expect(subject).to permit(user, organization)
      end
    end

    permissions :update?, :destroy?, :manage_members?, :manage_billing?, :change_subscription? do
      it 'denies access' do
        expect(subject).not_to permit(user, organization)
      end
    end
  end

  context 'for a viewer' do
    let(:user) { create(:user) }

    before do
      create(:membership, user: user, organization: organization, role: :viewer)
    end

    permissions :show? do
      it 'grants access' do
        expect(subject).to permit(user, organization)
      end
    end

    permissions :update?, :destroy?, :manage_members?, :manage_billing?, :change_subscription? do
      it 'denies access' do
        expect(subject).not_to permit(user, organization)
      end
    end
  end
end
