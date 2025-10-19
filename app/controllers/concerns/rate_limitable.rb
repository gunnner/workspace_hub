module RateLimitable
  extend ActiveSupport::Concern

  included do
    after_action :set_rate_limit_headers
  end

  private

  def set_rate_limit_headers
    if request.env['rack.attack.throttle_data']
      match_data = request.env['rack.attack.throttle_data']['api/token'] ||
                   request.env['rack.attack.throttle_data']['req/ip']

      if match_data
        response.headers['X-RateLimit-Limit']     = match_data[:limit].to_s
        response.headers['X-RateLimit-Remaining'] = [ match_data[:limit] - match_data[:count], 0 ].max.to_s
        response.headers['X-RateLimit-Reset']     = (match_data[:epoch_time] + match_data[:period]).to_s
        return
      end
    end

    # Fallback to manual calculation
    limit, period, count = rate_limit_info
    response.headers['X-RateLimit-Limit']     = limit.to_s
    response.headers['X-RateLimit-Remaining'] = [ limit - count, 0 ].max.to_s
    response.headers['X-RateLimit-Reset']     = (Time.current.to_i + period).to_s
  end


  def rate_limit_info
    current_user.present? ? api_token_rate_limit
                          : ip_rate_limit
  end

  def api_token_rate_limit
    limit  = 1_000
    period = 3_600
    count  = read_rate_limit_count('api/token', "api-token-#{current_user.api_token}", period)
    [ limit, period, count ]
  end

  def ip_rate_limit
    limit  = 100
    period = 3600
    count  = read_rate_limit_count('req/ip', request.ip, period)
    [ limit, period, count ]
  end

  def read_rate_limit_count(throttle_name, discriminator, period)
    epoch_time = Time.current.to_i / period
    cache_key = "rack::attack:#{epoch_time}:#{throttle_name}:#{discriminator}"
    Rack::Attack.cache.read(cache_key).to_i
  end
end
