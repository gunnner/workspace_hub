class TrialEndingReminderJob < BaseJob
  def perform
    log('Starting TrialEndingReminderJob')
    target_day    = 3.days.from_now
    subscriptions = Subscription.where(status: :trialing)
                                .where('trial_ends_at BETWEEN ? AND ?', target_day.beginning_of_day, target_day.end_of_day)
    log("Found #{subscriptions.count} subscriptions ending trial in 3 days")

    subscriptions.each do |subscription|
      organization = subscription.organization

      begin
        UserMailer.trial_ending_reminder_email(organization).deliver_later
        log("Sent trial reminder email to #{organization.name}")
      rescue StandardError => e
        log_error("Failed to send trial reminder for #{organization.name}: #{e.message}")
      end
    end

    log('TrialEndingReminderJob completed')
  end
end
