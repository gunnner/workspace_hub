Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'

    resource '/api/*',
      headers:     :any,
      methods:     [ :get, :post, :put, :patch, :delete, :options, :head ],
      credentials: false,
      expose:      [ 'Authorization' ]

    resource '/api-docs/*',
      headers:     :any,
      methods:     [ :get, :options ],
      credentials: false
  end
end
