# app/controllers/employees_controller.rb: Handles employee CRUD (free open-source Rails controller).
class EmployeesController < ApplicationController
  before_action :authenticate_user!

  # GET /employees
  def index
    @employees = current_user.clients.flat_map(&:employees)  # Fetch employees for current user's clients (free).
  end

  # GET /employees/:id/edit
  def edit
    @employee = Employee.find(params[:id])
  end

  # GET /employees/new
  def new
    @employee = Employee.new
  end

  # POST /employees
  def create
    @employee = Employee.new(employee_params)
    if @employee.save
      redirect_to dashboard_path(client_id: @employee.client_id), notice: 'Employee added successfully.'
    else
      render :new
    end
  end

  # PATCH/PUT /employees/:id
  def update
    @employee = Employee.find(params[:id])
    if @employee.update(employee_params)
      redirect_to dashboard_path(client_id: @employee.client_id), notice: 'Employee updated successfully.'
    else
      render :edit
    end
  end

  # DELETE /employees/:id
  def destroy
    @employee = Employee.find(params[:id])
    client_id = @employee.client_id
    @employee.destroy
    redirect_to dashboard_path(client_id: client_id), notice: 'Employee deleted successfully.'
  end

  private

  def employee_params
    params.require(:employee).permit(:name, :salary, :hours_worked, :title, :client_id)
  end
end