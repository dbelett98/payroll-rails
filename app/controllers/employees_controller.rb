# app/controllers/employees_controller.rb: Handles employee CRUD (free open-source Rails controller).
class EmployeesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_employee, only: [:edit, :update, :destroy]

  # GET /employees
  def index
    @employees = current_user.clients.flat_map(&:employees)  # Fetch employees for current user's clients (free).
  end

  # GET /employees/:id/edit
  def edit
  end

  # GET /employees/new
  def new
    @employee = Employee.new
  end

  # POST /employees
  def create
    @employee = Employee.new(employee_params)
    
    respond_to do |format|
      if @employee.save
        format.html { redirect_to dashboard_path(client_id: @employee.client_id), notice: 'Employee added successfully.' }
        format.json { render json: @employee, status: :created }
      else
        format.html { redirect_to dashboard_path(client_id: @employee.client_id), alert: "Error: #{@employee.errors.full_messages.join(', ')}" }
        format.json { render json: @employee.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /employees/:id
  def update
    respond_to do |format|
      if @employee.update(employee_params)
        format.html { redirect_to dashboard_path(client_id: @employee.client_id), notice: 'Employee updated successfully.' }
        format.json { render json: @employee, status: :ok }
      else
        format.html { redirect_to dashboard_path(client_id: @employee.client_id), alert: "Error: #{@employee.errors.full_messages.join(', ')}" }
        format.json { render json: @employee.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /employees/:id
  def destroy
    client_id = @employee.client_id
    @employee.destroy
    
    respond_to do |format|
      format.html { redirect_to dashboard_path(client_id: client_id), notice: 'Employee deleted successfully.' }
      format.json { head :no_content }
    end
  end

  private

  def set_employee
    @employee = Employee.find(params[:id])
  end

  def employee_params
    params.require(:employee).permit(:name, :salary, :hours_worked, :title, :client_id)
  end
end