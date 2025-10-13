require 'rails_helper'

RSpec.describe Subscription, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:organization) }
    it { should validate_presence_of(:plan) }
    it { should validate_presence_of(:status) }
  end

  describe 'associations' do
    it { should belong_to(:organization) }
    it { should belong_to(:plan) }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(trialing: 0, active: 1, past_due: 2, canceled: 3, unpaid: 4) }
  end

  describe 'trial period' do
    let(:subscription) { create(:subscription, :trialing) }

    it 'is on trial when status is trialing and trial_ends_at is in future' do
      expect(subscription.on_trial?).to be_truthy
    end

    it 'calculates days remaining correctly' do
      subscription.update(trial_ends_at: 5.days.from_now)

      expect(subscription.trial_days_remaining).to eq(5)
    end

    it 'returns false for on_trial? when trial ended' do
      subscription.update(trial_ends_at: 1.day.ago)

      expect(subscription.on_trial?).to    be_falsey
      expect(subscription.trial_ended?).to be_truthy
    end
  end

  describe 'status checks' do
    it 'returns true for active_subscription? when active' do
      subscription = build(:subscription, status: :active)

      expect(subscription.active_subscription?).to be_truthy
    end

    it 'returns true for active_subscription? when trialing' do
      subscription = create(:subscription, status: :trialing)
      expect(subscription.active_subscription?).to be_truthy
    end

    it 'returns false for can_access? when past_due' do
      subscription = build(:subscription, status: :past_due)

      expect(subscription.can_access?).to be_falsey
    end
  end

  describe 'cancellation' do
    let(:subscription) { create(:subscription) }
    it 'cancel subscription with reason' do
      subscription.cancel!(reason: 'Too expensive')

      expect(subscription.canceled?).to           be_truthy
      expect(subscription.canceled_at).to         be_present
      expect(subscription.cancellation_reason).to eq('Too expensive')
    end

    it 'reactivates canceled subscription' do
      subscription.cancel!
      subscription.reactivate!

      expect(subscription.active?).to             be_truthy
      expect(subscription.canceled_at).to         be_nil
      expect(subscription.cancellation_reason).to be_nil
    end
  end

  describe 'usage limits' do
    let(:plan)         { create(:plan, max_projects: 3, max_users: 5) }
    let(:organization) { create(:organization) }
    let(:subscription) { create(:subscription, organization: organization, plan: plan) }

    before do
      ActsAsTenant.current_tenant = organization
    end

    it 'checks project limit' do
      create_list(:project, 2, organization: organization)
      expect(subscription.can_create_project?).to be_truthy

      create(:project, organization: organization)
      expect(subscription.can_create_project?).to be_falsey
    end

    it 'allows unlimited projects for pro plan' do
      pro_plan = create(:plan, :pro, max_projects: nil)
      pro_subscription = create(:subscription, organization: organization, plan: pro_plan)

      create_list(:project, 101, organization: organization)
      expect(pro_subscription.can_create_project?).to be_truthy
    end
  end

  describe 'callbacks' do
    it 'sets trial period for paid plans' do
      plan = create(:plan, price_cents: 1_000)
      subscription = create(:subscription, plan: plan)

      expect(subscription.trial_ends_at).to be_present
      expect(subscription.trialing?).to be_truthy
    end

    it 'does not set trial for free plans' do
      plan = create(:plan, :free)
      subscription = create(:subscription, plan: plan, status: :active)

      expect(subscription.trial_ends_at).to be_nil
    end

    it 'sets billing period dates' do
      subscription = create(:subscription)

      expect(subscription.current_period_start).to be_present
      expect(subscription.current_period_end).to   be_present
    end
  end
end
