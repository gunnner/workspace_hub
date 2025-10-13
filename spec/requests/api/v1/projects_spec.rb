require 'rails_helper'

RSpec.describe 'Api::V1::Projects', type: :request do
  let(:organization) { create(:organization, subdomain: 'testorg') }
  let(:headers)      { { 'Host' => 'testorg.localhost' } }

  before do
    ActsAsTenant.current_tenant = organization
  end

  after do
    ActsAsTenant.current_tenant = nil
  end

  describe 'GET /api/v1/projects' do
    it 'returns all projects for current tenant' do
      create_list(:project, 3, organization: organization)

      get '/api/v1/projects', headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(3)
    end

    it 'does not return projects from other tenants' do
      other_org = create(:organization, subdomain: 'otherorg')

      create(:project, organization: organization, name: 'My Project')

      ActsAsTenant.with_tenant(other_org) do
        create(:project, organization: other_org, name: 'Other Project')
      end

      get '/api/v1/projects', headers: headers

      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first['name']).to eq('My Project')
    end
  end

  describe 'GET /api/v1/projects/:id' do
    let(:project) { create(:project, organization: organization) }

    it 'returns the project' do
      get "/api/v1/projects/#{project.id}", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['id']).to eq(project.id)
    end

    it 'returns 404 for project from another tenant' do
      other_org = create(:organization, subdomain: 'otherorg')
      other_project = ActsAsTenant.with_tenant(other_org) do
        create(:project, organization: other_org)
      end

      get "/api/v1/projects/#{other_project.id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/projects' do
    let(:valid_attributes) do
      { project: { name: 'New Project', description: 'Description' } }
    end

    it 'creates a new project' do
      expect do
        post '/api/v1/projects', params: valid_attributes, headers: headers, as: :json
      end.to change(Project, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['name']).to eq('New Project')
      expect(json['organization_id']).to eq(organization.id)
    end

    it 'returns errors for invalid attributes' do
      post '/api/v1/projects', params: { project: { name: '' } }, headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors']).to be_present
    end
  end

  describe 'PATCH /api/v1/projects/:id' do
    let(:project) { create(:project, organization: organization, name: 'Old Name') }

    it 'updates the project' do
      patch "/api/v1/projects/#{project.id}", params: { project: { name: 'New Name' } }, headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['name']).to eq('New Name')
    end

    it 'returns errors for invalid updates' do
      patch "/api/v1/projects/#{project.id}", params: { project: { name: '' } }, headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'DELETE /api/v1/projects/:id' do
    let!(:project) { create(:project, organization: organization) }

    it 'deletes the project' do
      expect do
        delete "/api/v1/projects/#{project.id}", headers: headers
      end.to change(Project, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'returns 404 for non-existent project' do
      delete '/api/v1/projects/99999', headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
