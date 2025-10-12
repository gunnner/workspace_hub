require 'rails_helper'

RSpec.describe Organization, type: :model do
  subject { build(:organization) }

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:subdomain) }
    it { should validate_uniqueness_of(:subdomain).case_insensitive }
  end

  describe 'associations' do
    it { should have_many(:memberships).dependent(:destroy) }
    it { should have_many(:users).through(:memberships) }
  end

  describe 'subdomain format' do
    it 'allows valid subdomains' do
      valid_subdomains = %w[valid test-123 my-company abc]

      valid_subdomains.each do |subdomain|
        org = build(:organization, subdomain: subdomain)
        expect(org).to be_valid, "Expected '#{subdomain}' to be valid"
      end
    end

    it 'rejects invalid subdomains' do
      invalid_subdomains = [ 'Invalid Subdomain!', 'my_company', 'test@123', 'a b c', 'TEST' ]

      invalid_subdomains.each do |subdomain|
        org = build(:organization, subdomain: subdomain)
        expect(org).to be_invalid, "Expected '#{subdomain}' to be invalid"
      end
    end

    it 'normalizes subdomain before validation' do
      org = create(:organization, subdomain: '  TeSt-123  ')
      expect(org.subdomain).to eq('test-123')
    end
  end

  describe 'reserved subdomains' do
    it 'rejects reserved subdomains' do
      reserved = %w[www admin api app blog help support mail ftp webmail localhost staging production test development docs status dashboard]

      reserved.each do |subdomain|
        org = build(:organization, subdomain: subdomain)
        expect(org).to be_invalid
        expect(org.errors[:subdomain]).to include("#{subdomain} is reserved")
      end
    end
  end
end
