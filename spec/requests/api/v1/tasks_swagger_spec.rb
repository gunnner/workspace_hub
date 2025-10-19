require 'rails_helper'
require 'swagger_helper'

RSpec.describe 'api/v1/tasks', type: :request do
  let(:organization)  { create(:organization, subdomain: 'testorg') }
  let(:user)          { create(:user) }
  let!(:membership)   { create(:membership, user: user, organization: organization, role: :member) }
  let(:project)       { create(:project, organization: organization) }
  let(:Authorization) { "Bearer #{user.api_token}" }
  let(:Host)          { 'testorg.localhost' }

  before do
    ActsAsTenant.current_tenant = organization
  end

  after do
    ActsAsTenant.current_tenant = nil
  end

  path '/api/v1/projects/{project_id}/tasks' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'
    parameter name: :Host, in: :header, type: :string, required: true,
              description: 'Organization subdomain',
              schema: { type: :string, default: 'testorg.localhost' }

    get('List all tasks for a project') do
      tags 'Tasks'
      description 'Returns all tasks for the specified project'
      produces 'application/json'
      security [ bearer_auth: [] ]

      response(200, 'successful') do
        schema type: :array,
               items: { '$ref' => '#/components/schemas/task' }

        let(:project_id) { project.id }
        let!(:tasks)     { create_list(:task, 3, project: project) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.length).to eq(3)
        end
      end

      response(401, 'unauthorized') do
        schema '$ref' => '#/components/schemas/error'

        let(:project_id)    { project.id }
        let(:Authorization) { nil }
        run_test!
      end

      response(404, 'project not found') do
        schema '$ref' => '#/components/schemas/error'

        let(:project_id) { 99999 }
        run_test!
      end
    end

    post('Create a task') do
      tags 'Tasks'
      description 'Creates a new task in the specified project'
      consumes 'application/json'
      produces 'application/json'
      security [ bearer_auth: [] ]

      parameter name: :task, in: :body, schema: {
        type: :object,
        properties: {
          task: {
            type: :object,
            properties: {
              title:       { type: :string, example: 'New Task' },
              description: { type: :string, example: 'Task description' },
              status:      { type: :string, enum: %w[todo in_progress completed], example: 'todo' }
            },
            required: [ 'title' ]
          }
        }
      }

      response(201, 'created') do
        schema '$ref' => '#/components/schemas/task'

        let(:project_id) { project.id }
        let(:task)       { { task: { title: 'New Task', description: 'Test task', status: 'todo' } } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['title']).to eq('New Task')
        end
      end

      response(422, 'invalid request') do
        schema '$ref' => '#/components/schemas/validation_errors'

        let(:project_id) { project.id }
        let(:task)       { { task: { title: '' } } }
        run_test!
      end

      response(403, 'forbidden') do
        schema '$ref' => '#/components/schemas/error'

        before do
          membership.update(role: :viewer)
        end

        let(:project_id) { project.id }
        let(:task)       { { task: { title: 'New Task' } } }
        run_test!
      end
    end
  end

  path '/api/v1/projects/{project_id}/tasks/{id}' do
    parameter name: :project_id, in: :path, type: :integer, description: 'Project ID'
    parameter name: :id, in: :path, type: :integer, description: 'Task ID'
    parameter name: :Host, in: :header, type: :string, required: true,
              description: 'Organization subdomain',
              schema: { type: :string, default: 'testorg.localhost' }

    get('Show a task') do
      tags 'Tasks'
      description 'Returns a specific task'
      produces 'application/json'
      security [ bearer_auth: [] ]

      response(200, 'successful') do
        schema '$ref' => '#/components/schemas/task'

        let(:project_id) { project.id }
        let(:id)         { create(:task, project: project).id }
        run_test!
      end

      response(404, 'not found') do
        schema '$ref' => '#/components/schemas/error'

        let(:project_id) { project.id }
        let(:id)         { 99999 }
        run_test!
      end
    end

    patch('Update a task') do
      tags 'Tasks'
      description 'Updates an existing task'
      consumes 'application/json'
      produces 'application/json'
      security [ bearer_auth: [] ]

      parameter name: :task, in: :body, schema: {
        type: :object,
        properties: {
          task: {
            type: :object,
            properties: {
              title:        { type: :string },
              description:  { type: :string },
              status:       { type: :string, enum: %w[todo in_progress completed] },
              completed_at: { type: :string, format: 'date-time' }
            }
          }
        }
      }

      response(200, 'successful') do
        schema '$ref' => '#/components/schemas/task'

        let(:project_id) { project.id }
        let(:id)         { create(:task, project: project, title: 'Old Title').id }
        let(:task)       { { task: { title: 'Updated Title', status: 'in_progress' } } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['title']).to eq('Updated Title')
        end
      end

      response(422, 'invalid request') do
        schema '$ref' => '#/components/schemas/validation_errors'

        let(:project_id) { project.id }
        let(:id)         { create(:task, project: project).id }
        let(:task)       { { task: { title: '' } } }
        run_test!
      end

      response(403, 'forbidden') do
        schema '$ref' => '#/components/schemas/error'

        before do
          membership.update(role: :viewer)
        end

        let(:project_id) { project.id }
        let(:id)         { create(:task, project: project).id }
        let(:task)       { { task: { title: 'Updated' } } }
        run_test!
      end
    end

    delete('Delete a task') do
      tags 'Tasks'
      description 'Deletes a task'
      security [ bearer_auth: [] ]

      response(204, 'no content') do
        let(:project_id) { project.id }
        let(:id) { create(:task, project: project).id }
        run_test!
      end

      response(403, 'forbidden') do
        schema '$ref' => '#/components/schemas/error'

        before do
          membership.update(role: :viewer)
        end

        let(:project_id) { project.id }
        let(:id)         { create(:task, project: project).id }
        run_test!
      end

      response(404, 'not found') do
        schema '$ref' => '#/components/schemas/error'

        let(:project_id) { project.id }
        let(:id)         { 99999 }
        run_test!
      end
    end
  end
end
