require 'rails_helper'

RSpec.describe 'Api::V1::Tasks', type: :request do
  let(:organization) { create(:organization, subdomain: 'testorg') }
  let(:user)         { create(:user) }
  let(:project)      { create(:project, organization: organization) }
  let(:api_token)    { user.api_token }
  let(:headers) do
    {
      'Host' => 'testorg.localhost',
      'Authorization' => "Bearer #{api_token}",
      'Content-Type'  => 'application/json'
    }
  end

  before do
    create(:membership, user: user, organization: organization, role: :member)
  end

  after do
    ActsAsTenant.current_tenant = nil
  end

  describe 'GET /api/v1/projects/:project_id/tasks' do
    it 'returns all tasks for the project' do
      ActsAsTenant.current_tenant = organization

      create_list(:task, 3, project: project)
      get api_v1_project_tasks_path(project), headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(3)
    end

    context 'without authentication' do
      it 'returns unauthorized' do
        ActsAsTenant.current_tenant = organization
        get api_v1_project_tasks_path(project), headers: { 'Host' => 'testorg.localhost' }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    it 'does not return tasks from other projects' do
      ActsAsTenant.current_tenant = organization
      other_project = create(:project, organization: organization)
      create(:task, project: project, title: 'Task 1')
      create(:task, project: other_project, title: 'Task 2')

      get api_v1_project_tasks_path(project), headers: headers

      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first['title']).to eq('Task 1')
    end
  end

  describe 'GET /api/v1/projects/:project_id/tasks/:id' do
    let(:task) { create(:task, project: project) }

    it 'returns the task' do
      ActsAsTenant.current_tenant = organization
      get api_v1_project_task_path(project, task), headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['id']).to eq(task.id)
      expect(json['project_id']).to eq(project.id)
    end

    it 'returns 404 for task from another project' do
      ActsAsTenant.current_tenant = organization
      other_project = create(:project, organization: organization)
      other_task    = create(:task, project: other_project)
      get api_v1_project_task_path(project, other_task), headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/projects/:project_id/tasks' do
    let(:valid_attributes) { { task: { title: 'New Task', description: 'Description', status: 'todo' } } }

    context 'as member' do
      it 'creates a new task' do
        ActsAsTenant.current_tenant = organization

        expect { post api_v1_project_tasks_path(project), params: valid_attributes.to_json, headers: headers }.to change(Task, :count).by(1)
        expect(response).to have_http_status(:created)
      end
    end

    context 'as viewer' do
      before do
        user.memberships.update_all(role: :viewer)
      end

      it 'denies access' do
        ActsAsTenant.current_tenant = organization
        post api_v1_project_tasks_path(project), params: valid_attributes.to_json, headers: headers

        expect(response).to have_http_status(:forbidden)
      end
    end

    it 'returns errors for invalid attributes' do
      ActsAsTenant.current_tenant = organization
      post api_v1_project_tasks_path(project), params: { task: { title: '' } }.to_json, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors']).to be_present
    end
  end

  describe 'PATCH /api/v1/projects/:project_id/tasks/:id' do
    let(:task) { create(:task, project: project, title: 'Old Title') }

    it 'updates the task' do
      ActsAsTenant.current_tenant = organization
      patch api_v1_project_task_path(project, task), params: { task: { title: 'New Title' } }.to_json, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['title']).to eq('New Title')
    end

    it 'returns errors for invalid updates' do
      ActsAsTenant.current_tenant = organization
      patch api_v1_project_task_path(project, task), params: { task: { title: '' } }.to_json, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'DELETE /api/v1/projects/:project_id/tasks/:id' do
    let!(:task) { create(:task, project: project) }

    it 'deletes the task' do
      ActsAsTenant.current_tenant = organization

      expect { delete api_v1_project_task_path(project, task), headers: headers }.to change(Task, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it 'returns 404 for non-existent task' do
      ActsAsTenant.current_tenant = organization
        delete api_v1_project_task_path(project, 99999), headers: headers

        expect(response).to have_http_status(:not_found)
    end
  end

  describe 'tenant isolation in nested resources' do
    it 'prevents access to tasks from other tenants' do
      ActsAsTenant.current_tenant = organization

      other_org = create(:organization, subdomain: 'otherorg')
      other_project = ActsAsTenant.with_tenant(other_org) do
        create(:project, organization: other_org)
      end

      get api_v1_project_tasks_path(other_project), headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
