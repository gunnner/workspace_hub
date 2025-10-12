class Api::V1::TasksController < ApiController
  before_action :set_project
  before_action :set_task, only: %i[show update destroy]

  # GET /api/v1/projects/:project_id/tasks
  def index
    @tasks = @project.tasks.order(created_at: :desc)

    render json: @tasks, status: :ok
  end

  # GET /api/v1/projects/:project_id/tasks/:id
  def show
    render json: @task, status: :ok
  end

  # POST /api/v1/projects/:project_id/tasks
  def create
    @task = @project.tasks.build(task_params)
    return render json: @task, status: :created if @task.save

    render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
  end

  # PATCH/PUT /api/v1/projects/:project_id/tasks/:id
  def update
    return render json: @task, status: :ok if @task.update(task_params)

    render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
  end

  # DELETE /api/v1/projects/:project_id/tasks/:id
  def destroy
    @task.destroy!

    head :no_content
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_task
    @task = @project.tasks.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :status, :completed_at)
  end
end
