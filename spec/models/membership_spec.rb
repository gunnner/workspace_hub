require 'rails_helper'

RSpec.describe Membership, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:organization) }
  end

  describe 'validations' do
    subject { build(:membership) }

    it { should validate_presence_of(:role) }
    it 'validates uniqueness of user_id scoped to organization_id' do
      org  = create(:organization)
      user = create(:user)
      create(:membership, user: user, organization: org)

      duplicate = build(:membership, user: user, organization: org)
      expect(duplicate).to be_invalid
      expect(duplicate.errors[:user_id]).to include('already belongs to this organization')
    end
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(owner: 0, admin: 1, member: 2, viewer: 3) }
  end

  describe 'role permissions' do
    let(:membership) { build(:membership) }

    describe '#can_manage_members?' do
      it 'returns true for owner' do
        membership.role = :owner

        expect(membership.can_manage_members?).to be_truthy
      end

      it 'returns true for admin' do
        membership.role = :admin

        expect(membership.can_manage_members?).to be_truthy
      end

      it 'returns false for member' do
        membership.role = :member

        expect(membership.can_manage_members?).to be_falsy
      end
    end

    describe '#can_manage_billing?' do
      it 'returns true only for owner' do
        membership.role = :owner
        expect(membership.can_manage_billing?).to be_truthy

        membership.role = :admin
        expect(membership.can_manage_billing?).to be_falsy
      end
    end

    describe '#can_create_projects?' do
      it 'returns true for owner, admin, member' do
        %i[owner admin member].each do |role|
          membership.role = role

          expect(membership.can_create_projects?).to be_truthy
        end
      end

      it 'returns false for viewer' do
        membership.role = :viewer

        expect(membership.can_create_projects?).to be_falsey
      end
    end
  end
end
