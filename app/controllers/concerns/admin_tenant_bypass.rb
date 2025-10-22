module AdminTenantBypass
  extend ActiveSupport::Concern

  included do
    around_action :without_tenant
  end

  private

  def without_tenant(&block)
    ActsAsTenant.without_tenant(&block)
  end
end
