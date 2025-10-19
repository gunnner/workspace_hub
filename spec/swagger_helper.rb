# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Workspace Hub API V1',
        version: 'v1',
        description: 'API documentation for Workspace Hub - a multi-tenant project management platform',
        contact: {
          name: 'API Support',
          url: 'https://github.com/gunnner/workspace_hub'
        }
      },
      paths: {},
      servers: [
        {
          url: 'http://{organization}.localhost:3000',
          description: 'Local development server',
          variables: {
            organization: {
              default: 'umbrella',
              description: 'Your organization subdomain'
            }
          }
        },
        {
          url: 'https://{organization}.yourdomain.com',
          description: 'Production server',
          variables: {
            organization: {
              default: 'demo',
              description: 'Your organization subdomain'
            }
          }
        }
      ],
      security: [
        { bearer_auth: [] }
      ],
      components: {
        securitySchemes: {
          bearer_auth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: 'JWT',
            description: 'Enter your API token (without "Bearer" prefix)'
          }
        },
        schemas: {
          project: {
            type: :object,
            properties: {
              id:              { type: :integer, example: 1 },
              organization_id: { type: :integer, example: 1 },
              name:            { type: :string, example: 'My Project' },
              description:     { type: :string, example: 'Project description', nullable: true },
              status:          { type: :string, enum: [ 'active', 'archived', 'completed' ], example: 'active' },
              created_by_id:   { type: :integer, example: 1, nullable: true },
              created_at:      { type: :string, format: 'date-time' },
              updated_at:      { type: :string, format: 'date-time' }
            },
            required: [ 'id', 'organization_id', 'name', 'status' ]
          },
          task: {
            type: :object,
            properties: {
              id:              { type: :integer, example: 1 },
              project_id:      { type: :integer, example: 1 },
              organization_id: { type: :integer, example: 1 },
              title:           { type: :string, example: 'My Task' },
              description:     { type: :string, example: 'Task description', nullable: true },
              status:          { type: :string, enum: [ 'todo', 'in_progress', 'completed' ], example: 'todo' },
              completed_at:    { type: :string, format: 'date-time', nullable: true },
              created_at:      { type: :string, format: 'date-time' },
              updated_at:      { type: :string, format: 'date-time' }
            },
            required: [ 'id', 'project_id', 'organization_id', 'title', 'status' ]
          },
          error: {
            type: :object,
            properties: {
              error: { type: :string, example: 'Record not found' }
            }
          },
          validation_errors: {
            type: :object,
            properties: {
              errors: {
                type: :array,
                items: { type: :string },
                example: [ "Name can't be blank" ]
              }
            }
          }
        }
      }
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
