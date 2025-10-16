class Api::V1::ProjectsController < ApiController
  before_action :set_project, only: %i[show update destroy]

  # GET /api/v1/projects
  def index
    @projects = policy_scope(Project).recent

    render json: @projects, status: :ok
  end

  # GET /api/v1/projects/:id
  def show
    authorize @project

    render json: @project, status: :ok
  end

  # POST /api/v1/projects
  def create
    @project = current_organization.projects.new(project_params)
    @project.created_by = current_user

    authorize @project
    return render json: @project, status: :created if @project.save

    render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
  end

  # PATCH/PUT /api/v1/projects/:id
  def update
    authorize @project
    return render json: @project, status: :ok if @project.update(project_params)

    render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
  end

  # DELETE /api/v1/projects/:id
  def destroy
    authorize @project

    @project.destroy!
    head :no_content
  end

  private

  def set_project
    @project = current_organization.projects.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description, :status)
  end
end
