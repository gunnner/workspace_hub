require 'rails_helper'

RSpec.describe 'Api::V1::Projects', type: :request do
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

  describe 'GET /api/v1/projects' do
    it 'returns all projects for current tenant' do
      create_list(:project, 3, organization: organization)
      get api_v1_projects_path, headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.size).to eq(3)
    end

    it 'does not return projects from other tenants' do
      other_org = create(:organization)
      ActsAsTenant.with_tenant(other_org) do
        create(:project, organization: other_org)
      end

      create(:project, organization: organization)
      get api_v1_projects_path, headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.size).to eq(1)
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        get api_v1_projects_path, headers: { 'Host' => 'testorg.localhost' }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/projects/:id' do
    let(:project) { create(:project, organization: organization) }

    it 'returns the project' do
      get api_v1_project_path(project), headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['id']).to eq(project.id)
    end

    it 'returns 404 for project from another tenant' do
      other_org = create(:organization)
      other_project = ActsAsTenant.with_tenant(other_org) do
        create(:project, organization: other_org)
      end
      get api_v1_project_path(other_project), headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/projects' do
    let(:valid_attributes) { { project: { name: 'New Project', description: 'Test' } } }

    context 'with valid params' do
      it 'creates a new project' do
        expect { post api_v1_projects_path, params: valid_attributes.to_json, headers: headers }.to change(Project, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['name']).to eq('New Project')
      end
    end

    context 'with invalid params' do
      it 'returns errors for invalid attributes' do
        post api_v1_projects_path, params: { project: { name: '' } }.to_json, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end
    end

    context 'as viewer' do
      before do
        user.memberships.update_all(role: :viewer)
      end

      it 'denies access' do
        post api_v1_projects_path, params: valid_attributes.to_json, headers: headers

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'PATCH /api/v1/projects/:id' do
    let(:project) { create(:project, organization: organization, created_by: user) }

    context 'as project creator' do
      it 'updates the project' do
        patch api_v1_project_path(project), params: { project: { name: 'Updated' } }.to_json, headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['name']).to eq('Updated')
      end
    end

    context 'as viewer' do
      before do
        user.memberships.update_all(role: :viewer)
      end

      it 'denies access' do
        patch api_v1_project_path(project), params: { project: { name: 'Updated' } }.to_json, headers: headers

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE /api/v1/projects/:id' do
    let!(:project) { create(:project, organization: organization, created_by: user) }

    context 'as project creator' do
      it 'deletes the project' do
        expect { delete api_v1_project_path(project), headers: headers }.to change(Project, :count).by(-1)

        expect(response).to have_http_status(:no_content)
      end
    end

    context 'as viewer' do
      before do
        user.memberships.update_all(role: :viewer)
      end

      it 'denies access' do
        delete api_v1_project_path(project), headers: headers

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
