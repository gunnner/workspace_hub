require 'rails_helper'

RSpec.describe 'ApiController', type: :request do
  let(:organization) { create(:organization, subdomain: 'testorg') }
  let(:headers)      { { 'Host' => 'testorg.localhost' } }

  before do
    ActsAsTenant.current_tenant = organization
  end

  after do
    ActsAsTenant.current_tenant = nil
  end

  describe 'tenant verification' do
    it 'works when tenant is set' do
      get '/api/v1/projects', headers: headers

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'error handling' do
    it 'returns 404 for non-existent records' do
      get '/api/v1/projects/99999', headers: headers

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Record not found')
    end
  end

  describe 'current_organization helper' do
    it 'is accessible in controllers' do
      create(:project, organization: organization, name: 'Test Project')

      get '/api/v1/projects', headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.first['organization_id']).to eq(organization.id)
    end
  end
end
