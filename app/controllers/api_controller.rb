class ApiController < ActionController::API
  include Pundit::Authorization

  before_action :verify_tenant
  before_action :authenticate_user!

  rescue_from ActsAsTenant::Errors::NoTenantSet, with: :tenant_required
  rescue_from ActiveRecord::RecordNotFound,      with: :record_not_found
  rescue_from Pundit::NotAuthorizedError,        with: :user_not_authorized

  private

  def verify_tenant
    render_tenant_not_found unless ActsAsTenant.current_tenant
  end

  def current_organization
    @current_organization ||= ActsAsTenant.current_tenant
  end

  def authenticate_user!
    token         = request.headers['Authorization']&.split(' ')&.last
    @current_user = User.find_by(api_token: token)

    render_unauthorized unless @current_user
  end

  def current_user
    @current_user
  end

  def tenant_required
    render json: { error: 'Tenant context required' }, status: :bad_request
  end

  def record_not_found
    render json: { error: 'Record not found' }, status: :not_found
  end

  def render_unauthorized
    render json: { error: 'Unauthorized. Valid API token required.' }, status: :unauthorized
  end

  def render_tenant_not_found
    render json: { error: 'Organization not found' }, status: :not_found
  end

  def user_not_authorized
    render json: { error: 'You are not authorized to perform this action' }, status: :forbidden
  end
end
