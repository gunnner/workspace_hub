require 'rails_helper'

RSpec.describe StripeWebhooksController, type: :request do
  let(:organization) { create(:organization, :with_subscription) }
  let(:plan)         { Plan.find_by!(slug: 'basic') }

  describe 'Subscription Model - Webhook Simulation' do
    describe 'checkout.session.completed webhook logic' do
      let(:stripe_subscription_id) { 'sub_test123' }
      let(:stripe_customer_id)     { 'cus_test123' }

      it 'updates subscription with Stripe data' do
        organization.subscription.update!(
          stripe_subscription_id: stripe_subscription_id,
          stripe_customer_id:     stripe_customer_id,
          status:                 :active,
          current_period_start:   Time.current,
          current_period_end:     1.month.from_now
        )

        organization.subscription.reload
        expect(organization.subscription.stripe_subscription_id).to eq(stripe_subscription_id)
        expect(organization.subscription.status).to eq('active')
      end

      it 'sets billing period correctly' do
        start_date = Time.current
        end_date   = 1.month.from_now

        organization.subscription.update!(current_period_start: start_date, current_period_end: end_date)

        organization.subscription.reload
        expect(organization.subscription.current_period_start).to be_present
        expect(organization.subscription.current_period_end).to   be_present
      end

      it 'handles trial subscription' do
        trial_end = 14.days.from_now

        organization.subscription.update!(status: :trialing, trial_ends_at: trial_end)

        organization.subscription.reload
        expect(organization.subscription.trialing?).to     be_truthy
        expect(organization.subscription.trial_ends_at).to be_present
      end
    end

    describe 'customer.subscription.updated webhook logic' do
      it 'updates subscription status' do
        organization.subscription.update!(
          stripe_subscription_id: 'sub_123',
          status:                 :active,
          current_period_start:   Time.current,
          current_period_end:     1.month.from_now
        )

        organization.subscription.reload
        expect(organization.subscription.status).to eq('active')
      end

      it 'updates cancel_at_period_end flag' do
        organization.subscription.update!(cancel_at_period_end: true)

        organization.subscription.reload
        expect(organization.subscription.cancel_at_period_end).to be_truthy
      end
    end

    describe 'customer.subscription.deleted webhook logic' do
      it 'marks subscription as canceled' do
        organization.subscription.update!(status: :canceled, canceled_at: Time.current)

        organization.subscription.reload
        expect(organization.subscription.canceled?).to   be_truthy
        expect(organization.subscription.canceled_at).to be_present
      end
    end

    describe 'invoice.payment_failed webhook logic' do
      it 'marks subscription as past_due' do
        organization.subscription.update!(status: :past_due)

        organization.subscription.reload
        expect(organization.subscription.status).to eq('past_due')
      end
    end
  end

  describe 'Billing Access Control' do
    let(:user)              { create(:user) }
    let(:owner_membership)  { create(:membership, user: user, organization: organization, role: :owner) }
    let(:member_membership) { create(:membership, user: user, organization: organization, role: :member) }

    describe 'Owner permissions' do
      before { owner_membership }

      it 'owner can manage billing' do
        expect(user.can_manage_billing_for?(organization)).to be_truthy
      end

      it 'owner_of? returns true' do
        expect(user.owner_of?(organization)).to be_truthy
      end
    end

    describe 'Member permissions' do
      before { member_membership }

      it 'member cannot manage billing' do
        expect(user.can_manage_billing_for?(organization)).to be_falsy
      end

      it 'owner_of? returns false' do
        expect(user.owner_of?(organization)).to be_falsy
      end
    end
  end

  describe 'Organization Subscription Limits' do
    describe 'project limits' do
      it 'checks project limit' do
        free_plan = Plan.find_by!(slug: 'free')
        organization.subscription.update!(plan: free_plan)

        expect(organization.subscription.within_project_limit?(2)).to be_truthy
        expect(organization.subscription.within_project_limit?(4)).to be_falsy
      end

      it 'allows unlimited projects for pro plan' do
        pro_plan = Plan.find_by!(slug: 'pro')
        organization.subscription.update!(plan: pro_plan)

        expect(organization.subscription.within_project_limit?(1000)).to be_truthy
      end
    end

    describe 'user limits' do
      it 'checks user limit' do
        basic_plan = Plan.find_by!(slug: 'basic')
        organization.subscription.update!(plan: basic_plan)

        expect(organization.subscription.within_user_limit?(4)).to be_truthy
        expect(organization.subscription.within_user_limit?(6)).to be_falsy
      end

      it 'allows unlimited users for pro plan' do
        pro_plan = Plan.find_by!(slug: 'pro')
        organization.subscription.update!(plan: pro_plan)

        expect(organization.subscription.within_user_limit?(1000)).to be_truthy
      end
    end
  end

  describe 'Plan Features' do
    describe 'Free plan' do
      let(:free_plan) { Plan.find_by!(slug: 'free') }

      it 'is free' do
        expect(free_plan.free?).to be_truthy
      end

      it 'has limited projects' do
        expect(free_plan.unlimited_projects?).to be_falsy
        expect(free_plan.max_projects).to eq(3)
      end

      it 'has limited users' do
        expect(free_plan.unlimited_users?).to be_falsy
        expect(free_plan.max_users).to eq(1)
      end

      it 'no API access' do
        expect(free_plan.api_access).to be_falsy
      end
    end

    describe 'Pro plan' do
      let(:pro_plan) { Plan.find_by!(slug: 'pro') }

      it 'is paid' do
        expect(pro_plan.free?).to be_falsy
        expect(pro_plan.paid?).to be_truthy
      end

      it 'has unlimited projects' do
        expect(pro_plan.unlimited_projects?).to be_truthy
      end

      it 'has unlimited users' do
        expect(pro_plan.unlimited_users?).to be_truthy
      end

      it 'has API access' do
        expect(pro_plan.api_access).to be_truthy
      end

      it 'has priority support' do
        expect(pro_plan.priority_support).to be_truthy
      end
    end
  end

  describe 'Subscription Status Checks' do
    describe 'active subscription' do
      it 'returns true when active' do
        organization.subscription.update!(status: :active)
        expect(organization.subscription.active_subscription?).to be_truthy
      end

      it 'returns true when trialing' do
        organization.subscription.update!(
          status: :trialing,
          trial_ends_at: 5.days.from_now
        )
        expect(organization.subscription.active_subscription?).to be_truthy
      end
    end

    describe 'trial status' do
      it 'returns true when on trial' do
        organization.subscription.update!(status: :trialing, trial_ends_at: 5.days.from_now)
        expect(organization.subscription.on_trial?).to be_truthy
      end

      it 'returns false when trial ended' do
        organization.subscription.update!(status: :trialing, trial_ends_at: 1.day.ago)
        expect(organization.subscription.on_trial?).to    be_falsy
        expect(organization.subscription.trial_ended?).to be_truthy
      end
    end

    describe 'past due status' do
      it 'returns true when past_due and period ended' do
        organization.subscription.update!(status: :past_due, current_period_end: 1.day.ago)
        expect(organization.subscription.past_due?).to be_truthy
      end
    end

    describe 'Webhook Mailer Notifications' do
      let(:subscription) { organization.subscription }

      describe 'handle_checkout_completed' do
        it 'sends payment success email' do
          stripe_subscription = instance_double(
            Stripe::Subscription,
            id:        'sub_123',
            customer:  'cus_123',
            status:    'active',
            trial_end: nil,
            items:     double(data: [ double(current_period_start: Time.current.to_i, current_period_end: 1.month.from_now.to_i) ])
          )

          session = instance_double(
            Stripe::Checkout::Session,
            subscription: 'sub_123',
            metadata: OpenStruct.new(organization_id: organization.id, plan_id: plan.id)
          )

          allow(Stripe::Subscription).to receive(:retrieve).and_return(stripe_subscription)
          allow(UserMailer).to receive_message_chain(:payment_success_email, :deliver_later)

          controller = StripeWebhooksController.new
          controller.send(:handle_checkout_completed, session)

          expect(UserMailer).to have_received(:payment_success_email).with(organization)
        end
      end

      describe 'handle_subscription_deleted' do
        it 'sends subscription canceled email' do
          subscription.update!(stripe_subscription_id: 'sub_999')
          subscription_data = instance_double(Stripe::Subscription, id: 'sub_999')

          allow(UserMailer).to receive_message_chain(:subscription_canceled_email, :deliver_later)

          controller = StripeWebhooksController.new
          controller.send(:handle_subscription_deleted, subscription_data)

          expect(UserMailer).to have_received(:subscription_canceled_email).with(organization)
        end
      end

      describe 'handle_payment_succeeded' do
        it 'sends subscription renewed email' do
          subscription.update!(stripe_customer_id: 'cus_777')
          invoice = instance_double(Stripe::Invoice, customer: 'cus_777')

          allow(UserMailer).to receive_message_chain(:subscription_renewed_email, :deliver_later)

          controller = StripeWebhooksController.new
          controller.send(:handle_payment_succeeded, invoice)

          expect(UserMailer).to have_received(:subscription_renewed_email).with(organization)
        end
      end

      describe 'handle_payment_failed' do
        it 'updates status and sends payment failed email' do
          subscription.update!(stripe_customer_id: 'cus_888', status: :active)
          invoice = instance_double(Stripe::Invoice, customer: 'cus_888')

          allow(UserMailer).to receive_message_chain(:payment_failed_email, :deliver_later)

          controller = StripeWebhooksController.new
          controller.send(:handle_payment_failed, invoice)

          subscription.reload
          expect(subscription.status).to eq('past_due')
          expect(UserMailer).to have_received(:payment_failed_email).with(organization)
        end
      end
    end
  end
end
