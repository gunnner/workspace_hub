class ApiController < ActionController::API
  before_action :verify_tenant_set

  rescue_from ActsAsTenant::Errors::NoTenantSet, with: :tenant_required
  rescue_from ActiveRecord::RecordNotFound,      with: :record_not_found

  private

  def verify_tenant_set
    return if ActsAsTenant.current_tenant.present?

    unless Rails.env.test?
      render json: { error: 'Tenant required' }, status: :bad_request
    end
  end

  def current_organization
    ActsAsTenant.current_tenant
  end

  def tenant_required
    render json: { error: 'Tenant context required' }, status: :bad_request
  end

  def record_not_found
    render json: { error: 'Record not found' }, status: :not_found
  end
end
