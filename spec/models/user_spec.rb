require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
  end

  describe 'associations' do
    it { should have_many(:memberships).dependent(:destroy) }
    it { should have_many(:organizations).through(:memberships) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      user = build(:user)
      expect(user).to be_valid
    end
  end

  describe 'callbacks' do
    it 'generates api token on create' do
      user = create(:user)

      expect(user.api_token).to be_present
    end

    it 'generates unique api_token' do
      user1 = create(:user)
      user2 = create(:user)

      expect(user1.api_token).not_to eq(user2.api_token)
    end
  end

  describe '#full_name' do
    it 'returns first and last name' do
      user = build(:user, first_name: 'Adam', last_name: 'Smith')

      expect(user.full_name).to eq('Adam Smith')
    end
  end

  describe '#initials' do
    it 'returns first letters of first and last name' do
      user = build(:user, first_name: 'Adam', last_name: 'Smith')

      expect(user.initials).to eq('AS')
    end
  end

  describe '#regenerate_api_token!' do
    it 'generates new api token' do
      user = create(:user)
      old_token = user.api_token

      user.regenerate_api_token!

      expect(user.api_token).not_to eq(old_token)
    end
  end
end
