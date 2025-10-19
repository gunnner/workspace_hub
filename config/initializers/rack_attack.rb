class Rack::Attack
  Rack::Attack.cache.store = Rails.cache

  # Throttle all requests by IP (100 requests per hour)
  throttle('req/ip', limit: 100, period: 1.hour) do |req|
    req.ip if req.path.start_with?('/api/')
  end

  # Throttle API requests by API token (1000 requests per hour)
  throttle('api/token', limit: 1000, period: 1.hour) do |req|
    if req.path.start_with?('/api/') && req.env['HTTP_AUTHORIZATION'].present?
      token = req.env['HTTP_AUTHORIZATION'].split(' ').last
      "api-token-#{token}" if token.present?
    end
  end

  # Throttle login attempts by email (5 attempts per 20 minutes)
  throttle('logins/email', limit: 5, period: 20.minutes) do |req|
    if req.path.eql?('/users/sign_in') && req.post?
      req.params['user']&.dig('email')&.to_s&.downcase&.strip
    end
  end

  # Throttle password reset requests (3 per hour per email)
  throttle('password_resets/email', limit: 3, period: 1.hour) do |req|
    if req.path.eql?('/users/password') && req.post?
      req.params['user']&.dig('email')&.to_s&.downcase&.strip
    end
  end

  blocklist('bad-user-agents') do |req|
    suspicious_agents = [ 'BadBot', 'Scrapy', 'wget' ]
    user_agent = req.user_agent.to_s.downcase
    suspicious_agents.any? { |agent| user_agent.include?(agent.downcase) }
  end

  self.throttled_responder = lambda do |request|
    match_data = request.env['rack.attack.match_data']
    now = match_data[:epoch_time]

    headers = {
      'Content-Type'          => 'application/json',
      'X-RateLimit-Limit'     => match_data[:limit].to_s,
      'X-RateLimit-Remaining' => '0',
      'X-RateLimit-Reset'     => (now + match_data[:period]).to_s
    }

    body = {
      error:      'Rate limit exceeded',
      message:    'Too many requests. Please try again later.',
      retry_after: match_data[:period]
    }

    [ 429, headers, [ body.to_json ] ]
  end

  self.blocklisted_responder = lambda do |request|
    [ 403, { 'Content-Type' => 'application/json' }, [ { error: 'Forbidden' }.to_json ] ]
  end
end
