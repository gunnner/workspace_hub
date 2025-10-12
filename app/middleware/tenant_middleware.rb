class TenantMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)

    subdomain = extract_subdomain(request)

    if subdomain.present?
      organization = Organization.find_by(subdomain: subdomain)
      return subdomain_not_found_response if organization.blank?

      ActsAsTenant.current_tenant = organization
    end

    @app.call(env)
  ensure
    ActsAsTenant.current_tenant = nil
  end

  private

  def extract_subdomain(request)
    host = request.host
    return nil if host.eql?('localhost') || host.match?(/\A\d+\.\d+\.\d+\.\d+\z/) # IP address

    parts = host.split('.')
    return parts.first if parts.many?

    nil
  end

  def subdomain_not_found_response
    [
      404,
      { 'Content-Type' => 'application/json' },
      [ { error: 'Subdomain not found' }.to_json ]
    ]
  end
end
