require 'rails_helper'
require 'swagger_helper'

RSpec.describe 'api/v1/projects', type: :request do
  let(:organization)  { create(:organization, subdomain: 'testorg') }
  let(:user)          { create(:user) }
  let!(:membership)   { create(:membership, user: user, organization: organization, role: :member) }
  let(:Authorization) { "Bearer #{user.api_token}" }
  let(:Host)          { 'testorg.localhost' }

  before do
    ActsAsTenant.current_tenant = organization
  end

  after do
    ActsAsTenant.current_tenant = nil
  end

  path '/api/v1/projects' do
    get('List all projects') do
      tags 'Projects'
      description 'Returns all projects for the current organization'
      produces 'application/json'
      security [ bearer_auth: [] ]

      parameter name: :Host, in: :header, type: :string, required: true,
                description: 'Organization subdomain (e.g., testorg.localhost)',
                schema: { type: :string, default: 'testorg.localhost' }

      response(200, 'successful') do
        schema type: :array,
               items: { '$ref' => '#/components/schemas/project' }

        let!(:projects) { create_list(:project, 3, organization: organization) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.length).to eq(3)
        end
      end

      response(401, 'unauthorized') do
        schema '$ref' => '#/components/schemas/error'
        let(:Authorization) { nil }
        run_test!
      end
    end

    post('Create a project') do
      tags 'Projects'
      description 'Creates a new project'
      consumes 'application/json'
      produces 'application/json'
      security [ bearer_auth: [] ]

      parameter name: :Host, in: :header, type: :string, required: true,
                description: 'Organization subdomain',
                schema: { type: :string, default: 'testorg.localhost' }

      parameter name: :project, in: :body, schema: {
        type: :object,
        properties: {
          project: {
            type: :object,
            properties: {
              name: { type: :string, example: 'New Project' },
              description: { type: :string, example: 'Project description' },
              status: { type: :string, enum: %w[active archived completed], example: 'active' }
            },
            required: [ 'name' ]
          }
        }
      }

      response(201, 'created') do
        schema '$ref' => '#/components/schemas/project'

        let(:project) { { project: { name: 'New Project', description: 'Test' } } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['name']).to eq('New Project')
        end
      end

      response(422, 'invalid request') do
        schema '$ref' => '#/components/schemas/validation_errors'

        let(:project) { { project: { name: '' } } }
        run_test!
      end

      response(403, 'forbidden') do
        schema '$ref' => '#/components/schemas/error'

        before do
          membership.update(role: :viewer)
        end

        let(:project) { { project: { name: 'New Project' } } }
        run_test!
      end
    end
  end

  path '/api/v1/projects/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'Project ID'

    parameter name: :Host, in: :header, type: :string, required: true,
    description: 'Organization subdomain',
    schema: { type: :string, default: 'testorg.localhost' }

    get('Show a project') do
      tags 'Projects'
      produces 'application/json'
      security [ bearer_auth: [] ]

      response(200, 'successful') do
        schema '$ref' => '#/components/schemas/project'

        let(:id) { create(:project, organization: organization).id }
        run_test!
      end

      response(404, 'not found') do
        schema '$ref' => '#/components/schemas/error'

        let(:id) { 'invalid' }
        run_test!
      end
    end

    patch('Update a project') do
      tags 'Projects'
      consumes 'application/json'
      produces 'application/json'
      security [ bearer_auth: [] ]

      parameter name: :project, in: :body, schema: {
        type: :object,
        properties: {
          project: {
            type: :object,
            properties: {
              name: { type: :string },
              description: { type: :string },
              status: { type: :string, enum: %w[active archived completed] }
            }
          }
        }
      }

      response(200, 'successful') do
        schema '$ref' => '#/components/schemas/project'

        let(:id)      { create(:project, organization: organization, created_by: user).id }
        let(:project) { { project: { name: 'Updated Name' } } }

        run_test!
      end

      response(403, 'forbidden') do
        schema '$ref' => '#/components/schemas/error'

        before do
          membership.update(role: :viewer)
        end

        let(:id)      { create(:project, organization: organization).id }
        let(:project) { { project: { name: 'Updated' } } }
        run_test!
      end
    end

    delete('Delete a project') do
      tags 'Projects'
      security [ bearer_auth: [] ]

      response(204, 'no content') do
        let(:id) { create(:project, organization: organization, created_by: user).id }
        run_test!
      end

      response(403, 'forbidden') do
        schema '$ref' => '#/components/schemas/error'

        before do
          membership.update(role: :viewer)
        end

        let(:id) { create(:project, organization: organization).id }
        run_test!
      end
    end
  end
end
