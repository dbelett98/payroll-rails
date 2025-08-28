# app/controllers/employees_controller.rb: Complete employee CRUD with modal error handling
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
    
    respond_to do |format|
      format.html
      format.json { 
        render json: @employee.as_json(
          include: { client: { only: [:id, :name] } },
          methods: [:calculate_pay]
        )
      }
    end
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
        format.json { render json: { success: true, employee: @employee, message: 'Employee added successfully.' } }
      else
        format.html { redirect_to dashboard_path(client_id: @employee.client_id), alert: "Error: #{@employee.errors.full_messages.join(', ')}" }
        format.json { render json: { success: false, errors: @employee.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /employees/:id
  def update
    puts "=== DEBUG: Update attempt ==="
    puts "Employee ID: #{@employee.id}"
    puts "Original title: #{@employee.title}"
    puts "Permitted params: #{employee_params.inspect}"
    
    respond_to do |format|
      if @employee.update(employee_params)
        puts "✅ SUCCESS: Employee updated! New title: #{@employee.reload.title}"
        format.html { redirect_to dashboard_path(client_id: @employee.client_id), notice: 'Employee updated successfully.' }
        format.json { render json: { success: true, employee: @employee, message: 'Employee updated successfully.' } }
      else
        puts "❌ FAILED: Update errors: #{@employee.errors.full_messages}"
        format.html { redirect_to dashboard_path(client_id: @employee.client_id), alert: "Error: #{@employee.errors.full_messages.join(', ')}" }
        format.json { render json: { success: false, errors: @employee.errors.full_messages }, status: :unprocessable_entity }
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

  # Bulk operations
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
    when 'change_department'
      Employee.where(id: employee_ids).update_all(department: params[:new_department])
      message = "Department updated for #{employee_ids.length} employees."
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
          filename: "#{@selected_client.name.gsub(/[^0-9A-Za-z.\-]/, '_')}_employees_#{Date.current}.csv" 
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

  # Complete parameter permissions for all Step L fields
  def employee_params
    params.require(:employee).permit(
      # Basic Information
      :name, :title, :department, :hire_date, :employment_type, :status, :client_id,
      # Payroll Information  
      :salary, :hours_worked, :pay_frequency,
      # Contact Information
      :address, :phone, :email, :emergency_contact_name, 
      :emergency_contact_phone, :emergency_contact_relationship,
      # Banking Information (for future)
      :bank_routing_number, :bank_account_number,
      # Tax Information (for future)
      :ssn, :federal_withholding_allowances, :federal_additional_withholding,
      :state_withholding_allowances, :state_additional_withholding, :marital_status
    )
  end

  def generate_csv(employees)
    require 'csv'
    CSV.generate(headers: true) do |csv|
      csv << [
        'Name', 'Title', 'Department', 'Employment Type', 'Status',
        'Hire Date', 'Salary', 'Pay Frequency', 'Hours Worked', 
        'Phone', 'Email', 'Address', 'Emergency Contact', 'Emergency Phone'
      ]
      
      employees.each do |employee|
        csv << [
          employee.name, employee.title, employee.department,
          employee.employment_type, employee.status, employee.hire_date,
          employee.salary, employee.pay_frequency, employee.hours_worked,
          employee.phone, employee.email, employee.address,
          employee.emergency_contact_name, employee.emergency_contact_phone
        ]
      end
    </end>
  end
end