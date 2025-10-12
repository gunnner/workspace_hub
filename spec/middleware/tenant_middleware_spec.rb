require 'rails_helper'

RSpec.describe TenantMiddleware do
  let(:app) { ->(env) { [ 200, env, 'success' ] } }
  let(:middleware) { TenantMiddleware.new(app) }

  describe 'subdomain extraction' do
    it 'sets tenant for valid subdomain' do
      org = create(:organization, subdomain: 'testorg')
      app = ->(_env) do
        expect(ActsAsTenant.current_tenant).to eq(org)
        [ 200, {}, [ 'ok' ] ]
      end

      middleware = TenantMiddleware.new(app)
      env = Rack::MockRequest.env_for('http://testorg.localhost:3000/')
      middleware.call(env)
    end

    it 'returns 404 for non-existen subdomain' do
      env = Rack::MockRequest.env_for('http://nonexistent.localhost:3000/')
      status, _headers, _body = middleware.call(env)

      expect(status).to eq(404)
    end

    it 'allows requests without subdomain' do
      env = Rack::MockRequest.env_for('http://localhost:3000/')
      status, _headers, _body = middleware.call(env)
      expect(status).to eq(200)
    end
  end

  describe 'tenant cleanup' do
    it 'resets tenant after request' do
      org = create(:organization, subdomain: 'testorg')
      env = Rack::MockRequest.env_for('http://testorg.localhost:3000/')
      middleware.call(env)

      expect(ActsAsTenant.current_tenant).to be_nil
    end
  end
end
