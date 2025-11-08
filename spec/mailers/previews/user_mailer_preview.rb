# http://localhost:3000/rails/mailers

class UserMailerPreview < ActionMailer::Preview
  def payment_success_email
    UserMailer.payment_success_email(organization)
  end

  def payment_failed_email
    UserMailer.payment_failed_email(organization)
  end

  def trial_ending_reminder_email
    UserMailer.trial_ending_reminder_email(organization)
  end

  def subscription_canceled_email
    UserMailer.subscription_canceled_email(organization)
  end

  def subscription_renewed_email
    UserMailer.subscription_renewed_email(organization)
  end

  def organization
    @organization ||= Organization.first
  end
end
