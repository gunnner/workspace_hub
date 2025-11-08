class UserMailer < ApplicationMailer
  def payment_success_email(organization)
    send_mail(organization, "Payment Received - #{plan(organization).name} Plan")
  end

  def payment_failed_email(organization)
    send_mail(organization, 'Payment Failed - Action Required')
  end

  def trial_ending_reminder_email(organization)
    @days_left = (((subscription(organization).trial_ends_at&.to_date || Date.yesterday) - Date.today).to_i)
    send_mail(organization, "Your Trial Ends in #{@days_left} Days")
  end

  def subscription_canceled_email(organization)
    send_mail(organization, 'Your Subscription Has Been Canceled')
  end

  def subscription_renewed_email(organization)
    @renewal_date = subscription(organization)&.current_period_end
    send_mail(organization, 'Your Subscription Has Been Renewed')
  end

  private

  def send_mail(organization, subject)
    @organization = organization_model(organization)
    @subscription = subscription(organization)
    @plan         = plan(organization)
    @owner        = owner(organization)

    mail(
      to:      email(organization),
      subject: subject
    )
  end

  def organization_model(organization)
    @organization ||= organization
  end

  def subscription(organization)
    @subscription ||= organization_model(organization).subscription
  end

  def plan(organization)
    @plan ||= subscription(organization)&.plan
  end

  def email(organization)
    @email ||= owner(organization)&.email
  end

  def owner(organization)
    @owner = organization_model(organization).owners.first
  end
end
