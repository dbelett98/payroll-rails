# app/controllers/employees_controller.rb: Enhanced employee CRUD with payroll features
class EmployeesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_employee, only: [:show, :edit, :update, :destroy]

  # GET /employees (redirect to dashboard)
  def index
    redirect_to dashboard_path
  end

  # GET /employees/:id (Employee Profile Page)
  def show
    @client = @employee.client
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

  # Bulk update for multiple employees
  def bulk_update
    employee_ids = params[:employee_ids] || []
    action_type = params[:bulk_action]
    
    case action_type
    when 'activate'
      Employee.where(id: employee_ids).update_all(status: 'active')
      message = "#{employee_ids.length} employees activated."
    when 'deactivate'
      Employee.where(id: employee_ids).update_all(status: 'inactive')
      message = "#{employee_ids.length} employees deactivated."
    when 'export'
      # Handle export logic here
      message = "#{employee_ids.length} employees exported."
    end
    
    redirect_to dashboard_path(client_id: params[:client_id]), notice: message
  end

  # CSV export
  def export_csv
    @selected_client_id = params[:client_id]
    @selected_client = Client.find(@selected_client_id) if @selected_client_id
    
    if @selected_client
      @employees = @selected_client.employees.order(:name)
      
      respond_to do |format|
        format.csv { 
          send_data generate_csv(@employees), 
          filename: "#{@selected_client.name}_employees_#{Date.current}.csv" 
        }
      end
    else
      redirect_to dashboard_path, alert: 'Please select a client first.'
    end
  end

  private

  def set_employee
    @employee = Employee.find(params[:id])
  end

  def employee_params
    params.require(:employee).permit(
      :name, :salary, :hours_worked, :title, :client_id, 
      :ssn, :bank_routing_number, :bank_account_number,
      :hire_date, :employment_type, :department, :pay_frequency, 
      :status, :federal_withholding_allowances, :federal_additional_withholding,
      :state_withholding_allowances, :state_additional_withholding,
      :marital_status, :address, :phone, 
      :emergency_contact_name, :emergency_contact_phone
    )
  end

  def generate_csv(employees)
    require 'csv'
    CSV.generate(headers: true) do |csv|
      csv << [
        'Name', 'Title', 'Department', 'Employment Type', 'Status',
        'Hire Date', 'Salary', 'Pay Frequency', 'Phone', 'Address'
      ]
      
      employees.each do |employee|
        csv << [
          employee.name, employee.title, employee.department,
          employee.employment_type, employee.status, employee.hire_date,
          employee.salary, employee.pay_frequency, employee.phone,
          employee.address
        ]
      end
    end
  end
end