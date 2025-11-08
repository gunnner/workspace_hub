require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  let(:organization) { create(:organization, :with_subscription) }
  let(:subscription) { organization.subscription }
  let(:owner)        { organization.owners.first }
  let(:plan)         { subscription.plan }

  describe '#payment_success_email' do
    let(:email) { UserMailer.payment_success_email(organization) }

    it 'renders headers' do
      expect(email.subject).to include('Payment Received')
      expect(email.to).to eq([ owner.email ])
      expect(email.from).to eq([ 'noreply@workspacehub.com' ])
    end
  end

  describe '#payment_failed_email' do
    let(:email) { UserMailer.payment_failed_email(organization) }

    it 'renders headers' do
      expect(email.subject).to include('Payment Failed')
      expect(email.to).to eq([ owner.email ])
    end
  end

  describe '#trial_ending_reminder_email' do
    let(:email) { UserMailer.trial_ending_reminder_email(organization) }

    it 'renders headers' do
      expect(email.subject).to include('Your Trial Ends')
      expect(email.to).to eq([ owner.email ])
      expect(email.from).to eq([ 'noreply@workspacehub.com' ])
    end
  end

  describe '#subscription_canceled_email' do
    let(:email) { UserMailer.subscription_canceled_email(organization) }

    it 'renders headers' do
      expect(email.subject).to include('Canceled')
      expect(email.to).to eq([ owner.email ])
    end
  end

  describe '#subscription_renewed_email' do
    let(:email) { UserMailer.subscription_renewed_email(organization) }

    it 'renders headers' do
      expect(email.subject).to include('Renewed')
      expect(email.to).to eq([ owner.email ])
    end
  end
end
