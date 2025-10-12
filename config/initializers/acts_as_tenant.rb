ActsAsTenant.configure do |config|
  config.require_tenant = !Rails.env.test?
end
