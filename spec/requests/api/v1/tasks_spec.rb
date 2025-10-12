require 'rails_helper'

RSpec.describe 'Api::V1::Tasks', type: :request do
  let(:organization) { create(:organization, subdomain: 'testorg') }
  let(:project) { create(:project, organization: organization) }
  let(:headers) { { 'Host' => 'testorg.localhost' } }

  before do
    ActsAsTenant.current_tenant = organization
  end

  after do
    ActsAsTenant.current_tenant = nil
  end

  describe 'GET /api/v1/projects/:project_id/tasks' do
    it 'returns all tasks for the project' do
      tasks = create_list(:task, 3, project: project)

      get "/api/v1/projects/#{project.id}/tasks", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.length).to eq(3)
    end

    it 'does not return tasks from other projects' do
      other_project = create(:project, organization: organization)

      task1 = create(:task, project: project, title: 'Task 1')
      task2 = create(:task, project: other_project, title: 'Task 2')

      get "/api/v1/projects/#{project.id}/tasks", headers: headers

      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first['title']).to eq('Task 1')
    end
  end

  describe 'GET /api/v1/projects/:project_id/tasks/:id' do
    let(:task) { create(:task, project: project) }

    it 'returns the task' do
      get "/api/v1/projects/#{project.id}/tasks/#{task.id}", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['id']).to eq(task.id)
      expect(json['project_id']).to eq(project.id)
    end

    it 'returns 404 for task from another project' do
      other_project = create(:project, organization: organization)
      other_task = create(:task, project: other_project)

      get "/api/v1/projects/#{project.id}/tasks/#{other_task.id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/projects/:project_id/tasks' do
    let(:valid_attributes) do
      { task: { title: 'New Task', description: 'Description', status: 'todo' } }
    end

    it 'creates a new task' do
      expect do
        post "/api/v1/projects/#{project.id}/tasks", params: valid_attributes, headers: headers, as: :json
      end.to change(Task, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['title']).to eq('New Task')
      expect(json['project_id']).to eq(project.id)
      expect(json['organization_id']).to eq(organization.id)
    end

    it 'returns errors for invalid attributes' do
      post "/api/v1/projects/#{project.id}/tasks", params: { task: { title: '' } }, headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors']).to be_present
    end
  end

  describe 'PATCH /api/v1/projects/:project_id/tasks/:id' do
    let(:task) { create(:task, project: project, title: 'Old Title') }

    it 'updates the task' do
      patch "/api/v1/projects/#{project.id}/tasks/#{task.id}", params: { task: { title: 'New Title' } }, headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['title']).to eq('New Title')
    end

    it 'returns errors for invalid updates' do
      patch "/api/v1/projects/#{project.id}/tasks/#{task.id}", params: { task: { title: '' } }, headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'DELETE /api/v1/projects/:project_id/tasks/:id' do
    let!(:task) { create(:task, project: project) }

    it 'deletes the task' do
      expect do
        delete "/api/v1/projects/#{project.id}/tasks/#{task.id}", headers: headers
      end.to change(Task, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'returns 404 for non-existent task' do
      delete "/api/v1/projects/#{project.id}/tasks/99999", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'tenant isolation in nested resources' do
    it 'prevents access to tasks from other tenants' do
      other_org = create(:organization, subdomain: 'otherorg')
      other_project = ActsAsTenant.with_tenant(other_org) do
        create(:project, organization: other_org)
      end

      get "/api/v1/projects/#{other_project.id}/tasks", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
