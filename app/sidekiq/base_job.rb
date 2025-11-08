class BaseJob
  include Sidekiq::Job

  def log(msg)
    Rails.logger.info(msg)
  end

  def log_error(msg)
    Rails.logger.error(msg)
  end
end
