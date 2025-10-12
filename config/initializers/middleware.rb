require Rails.root.join('app/middleware/tenant_middleware')

Rails.application.config.middleware.use TenantMiddleware
