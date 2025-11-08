require 'rails_helper'

describe TrialEndingReminderJob, type: :job do
  let(:organization_active_trial)  { create(:organization, :with_subscription) }
  let(:organization_ending_soon)   { create(:organization, :with_subscription) }
  let(:organization_already_ended) { create(:organization, :with_subscription) }

  before do
    organization_ending_soon.subscription.update!(status: :trialing, trial_ends_at: 3.days.from_now)
    organization_already_ended.subscription.update!(status: :trialing, trial_ends_at: 1.day.ago)
    organization_active_trial.subscription.update!(status: :trialing, trial_ends_at: 10.days.from_now)
  end

  describe '#perform' do
    it 'sends email only to subscriptions ending in 3 days' do
      expect { TrialEndingReminderJob.new.perform }.to have_enqueued_job(ActionMailer::MailDeliveryJob).at_least(:once)
    end

    it 'sends email to organization with trial ending in 3 days' do
      allow(UserMailer).to receive_message_chain(:trial_ending_reminder_email, :deliver_later)
      TrialEndingReminderJob.new.perform

      expect(UserMailer).to have_received(:trial_ending_reminder_email).with(organization_ending_soon)
    end

    it 'does not send email to organization with active trial' do
      allow(UserMailer).to receive_message_chain(:trial_ending_reminder_email, :deliver_later)
      TrialEndingReminderJob.new.perform

      expect(UserMailer).not_to have_received(:trial_ending_reminder_email).with(organization_active_trial)
    end

    it 'does not send email to organization with ended trial' do
      allow(UserMailer).to receive_message_chain(:trial_ending_reminder_email, :deliver_later)
      TrialEndingReminderJob.new.perform

      expect(UserMailer).not_to have_received(:trial_ending_reminder_email).with(organization_already_ended)
    end

    it 'handles errors gracefully' do
      allow(UserMailer).to receive_message_chain(:trial_ending_reminder_email, :deliver_later).and_raise(StandardError, 'Email delivery failed')

      expect { TrialEndingReminderJob.new.perform }.not_to raise_error
    end
  end
end
