class Api::V1::ProjectsController < ApiController
  before_action :set_project, only: %i[show update destroy]

  # GET /api/v1/projects
  def index
    @projects = Project.all.recent

    render json: @projects, status: :ok
  end

  # GET /api/v1/projects/:id
  def show
    render json: @project, status: :ok
  end

  # POST /api/v1/projects
  def create
    @project = Project.new(project_params)
    @project.organization = current_organization
    return render json: @project, status: :created if @project.save

    render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
  end

  # PATCH/PUT /api/v1/projects/:id
  def update
    return render json: @project, status: :ok if @project.update(project_params)

    render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
  end

  # DELETE /api/v1/projects/:id
  def destroy
    @project.destroy!

    head :no_content
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description, :status)
  end
end
