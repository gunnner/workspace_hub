require 'rails_helper'

RSpec.describe ApiController, type: :request do
  let(:organization) { create(:organization, subdomain: 'testorg') }
  let(:user)         { create(:user) }
  let(:api_token)    { user.api_token }
  let(:headers) do
    {
      'Host'          => 'testorg.localhost',
      'Authorization' => "Bearer #{api_token}",
      'Content-Type'  => 'application/json'
    }
  end

  before do
    create(:membership, user: user, organization: organization, role: :member)
    ActsAsTenant.current_tenant = organization
  end

  after do
    ActsAsTenant.current_tenant = nil
  end

  describe 'tenant verification' do
    it 'works when tenant is set' do
      get api_v1_projects_path, headers: headers

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'error handling' do
    it 'returns 404 for non-existent records' do
      get api_v1_project_path(99999), headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'current_organization helper' do
    it 'is accessible in controllers' do
      get api_v1_projects_path, headers: headers

      expect(response).to have_http_status(:ok)
    end
  end
end
