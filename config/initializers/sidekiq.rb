schedule_file = 'config/schedule.yml'.freeze
redis_config  = {
  url:     ENV['REDIS_URL'],
  timeout: ENV['SIDEKIQ_POOL_TIMEOUT'].to_f,
  size:    ENV['SIDEKIQ_POOL_SIZE'].to_i
}.freeze

Sidekiq.configure_server do |config|
  config.on(:startup) do
    if File.exist?(schedule_file)
      schedule = YAML.load_file(schedule_file)
      Sidekiq::Cron::Job.load_from_hash!(schedule, source: 'schedule')
    end
  end
  config.redis  = redis_config
  config.logger = Sidekiq::Logger.new($stdout)
  config.death_handlers << ->(job, ex) do
    Rails.logger.error("Sidekiq job failed: #{job['class']} #{job['jid']} just died with error #{ex.message}. With args #{job['args']}")
  end
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end
