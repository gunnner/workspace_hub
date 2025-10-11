require 'rails_helper'

RSpec.describe Membership, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:organization) }
  end

  describe 'validations' do
    subject { build(:membership) }

    it { should validate_presence_of(:role) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:organization_id) }
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(member: 0, admin: 1, owner: 2) }
  end
end
