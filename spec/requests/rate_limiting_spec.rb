require 'rails_helper'

RSpec.describe 'Rate Limiting', type: :request do
  let(:organization) { create(:organization, subdomain: 'testorg') }
  let(:user)         { create(:user) }
  let!(:membership)  { create(:membership, user: user, organization: organization, role: :member) }
  let(:headers) do
    {
      'Host'          => 'testorg.localhost',
      'Authorization' => "Bearer #{user.api_token}",
      'Content-Type'  => 'application/json'
    }
  end

  before do
    ActsAsTenant.current_tenant = organization
    Rack::Attack.cache.store.clear
  end

  after do
    ActsAsTenant.current_tenant = nil
  end

  describe 'API rate limiting' do
    it 'allows requests under the limit' do
      5.times do
        get api_v1_projects_path, headers: headers

        expect(response).to have_http_status(:success)
      end
    end

    it 'blocks requests over the IP limit' do
      # debugger
      allow_any_instance_of(Rack::Request).to receive(:ip).and_return('1.2.3.4')

      100.times do
        get api_v1_projects_path, headers: headers
      end

      get api_v1_projects_path, headers: headers

      expect(response).to have_http_status(429)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Rate limit exceeded')
    end

    it 'includes rate limit headers in response' do
      get api_v1_projects_path, headers: headers

      expect(response.headers['X-RateLimit-Limit']).to     be_present
      expect(response.headers['X-RateLimit-Remaining']).to be_present
      expect(response.headers['X-RateLimit-Reset']).to     be_present
    end
  end

  describe 'Login rate limiting' do
    it 'allows multiple login attempts under the limit' do
      3.times do
        post user_session_path, params: { user: { email: 'test@example.com', password: 'wrong' } }, headers: { 'Host' => 'testorg.localhost' }
      end

      expect(response.status).to be_in([ 200, 401, 422 ])
    end
  end

  describe 'Rate limit headers' do
    it 'includes accurate rate limit information' do
      get api_v1_projects_path, headers: headers

      limit = response.headers['X-RateLimit-Limit'].to_i
      remaining_before = response.headers['X-RateLimit-Remaining'].to_i
      reset = response.headers['X-RateLimit-Reset']

      expect(limit).to            eq(1000)
      expect(remaining_before).to eq(999)
      expect(reset).to            be_present

      get api_v1_projects_path, headers: headers
      remaining_after = response.headers['X-RateLimit-Remaining'].to_i

      expect(remaining_after).to eq(998)
    end

    it 'shows correct remaining count after multiple requests' do
      5.times do |i|
        get api_v1_projects_path, headers: headers

        remaining = response.headers['X-RateLimit-Remaining'].to_i
        expect(remaining).to eq(1000 - (i + 1))
      end
    end

    it 'uses IP-based limit for unauthenticated requests' do
      get api_v1_projects_path, headers: { 'Host' => 'testorg.localhost' }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
