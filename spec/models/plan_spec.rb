require 'rails_helper'

RSpec.describe Plan, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:slug) }
    it { should validate_presence_of(:price_cents) }
    it { should validate_presence_of(:interval) }

    subject { build(:plan) }
    it { should validate_uniqueness_of(:slug) }
  end

  describe 'associations' do
    it { should have_many(:subscriptions) }
    it { should have_many(:organizations).through(:subscriptions) }
  end

  describe 'scopes' do
    it 'orders by price with by_price scope' do
      free_plan  = Plan.find_by!(slug: 'free')
      basic_plan = Plan.find_by!(slug: 'basic')
      pro_plan   = Plan.find_by!(slug: 'pro')
      expensive  = create(:plan, name: 'Expensive Plan', slug: 'expensive', price_cents: 10_000)
      plans      = Plan.by_price

      expect(plans.first).to  eq(free_plan)
      expect(plans.second).to eq(basic_plan)
      expect(plans.third).to  eq(pro_plan)
      expect(plans.last).to   eq(expensive)
    end
  end

  describe 'price helpers' do
    let(:plan) { create(:plan, price_cents: 2_500) }

    it 'returns true for free plan' do
      free_plan = build(:plan, :free)

      expect(free_plan.free?).to be_truthy
    end

    it 'return false for paid plan' do
      expect(plan.free?).to be_falsy
    end
  end

  describe 'interval checks' do
    it 'identifies monthly plans' do
      plan = build(:plan, interval: 'month')

      expect(plan.monthly?).to be_truthy
      expect(plan.yearly?).to  be_falsy
    end

    it 'identifies yearly plans' do
      plan = build(:plan, interval: 'year')

      expect(plan.yearly?).to  be_truthy
      expect(plan.monthly?).to be_falsy
    end
  end

  describe 'feature checks' do
    it 'checks if feature is enabled' do
      plan = build(:plan, features: { 'webhooks' => true, 'export' => false })

      expect(plan.feature_enabled?('webhooks')).to be_truthy
      expect(plan.feature_enabled?(:webhooks)).to  be_truthy
      expect(plan.feature_enabled?('export')).to   be_falsy
      expect(plan.feature_enabled?(:export)).to    be_falsy
    end
  end

  describe 'unlimited checks' do
    it 'returns true when max_projects is nil' do
      plan = build(:plan, max_projects: nil)

      expect(plan.unlimited_projects?).to be_truthy
    end

    it 'returns false when max_projects is set' do
      plan = build(:plan, max_projects: 1)

      expect(plan.unlimited_projects?).to be_falsy
    end

    it 'returns true when max_users is nil' do
      plan = build(:plan, max_users: nil)

      expect(plan.unlimited_users?).to be_truthy
    end

    it 'returns false when max_users is set' do
      plan = build(:plan, max_users: 1)

      expect(plan.unlimited_users?).to be_falsy
    end
  end
end
