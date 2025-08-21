# app/controllers/employees_controller.rb: Handles employee CRUD (free open-source Rails controller).
class EmployeesController < ApplicationController
  before_action :authenticate_user!

  # GET /employees
  def index
    @employees = current_user.clients.flat_map(&:employees)  # Fetch employees for current user's clients (free).
  end

  # GET /employees/new
  def new
    @employee = Employee.new
  end

  # POST /employees
  def create
    @employee = Employee.new(employee_params)
    if @employee.save
      redirect_to dashboard_path, notice: 'Employee added successfully.'
    else
      render :new
    end
  end

  private

  def employee_params
    params.require(:employee).permit(:name, :salary, :hours_worked, :title, :client_id)
  end
end