# app/controllers/employees_controller.rb
class EmployeesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_employee, only: [:show, :edit, :update, :destroy]

  def index
    redirect_to dashboard_path
  end

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

  def new
    @employee = Employee.new
    @employee.client_id = params[:client_id]
    @employee.hire_date = Date.current
    @employee.employment_type = 'W2'
    @employee.pay_frequency = 'biweekly'
    @employee.status = 'active'
    @employee.federal_withholding_allowances = 0
    @employee.state_withholding_allowances = 0
    @employee.federal_additional_withholding = 0.0
    @employee.state_additional_withholding = 0.0
    render :edit
  end

  def create
    @employee = Employee.new(employee_params)
    
    puts "=== DEBUG: Create attempt ==="
    puts "Permitted params: #{employee_params.inspect}"
    
    if @employee.save
      puts "✅ SUCCESS: Employee created successfully"
      redirect_to dashboard_path(client_id: @employee.client_id), notice: 'Employee added successfully.'
    else
      puts "❌ FAILED: Create errors: #{@employee.errors.full_messages}"
      render :edit, status: :unprocessable_entity
    end
  end

  def edit
    # Employee is set by before_action
  end

  def update
    puts "=== DEBUG: Update attempt ==="
    puts "Employee ID: #{@employee.id}"
    puts "Original title: #{@employee.title}"
    puts "Permitted params: #{employee_params.inspect}"
    puts "Raw params: #{params[:employee].inspect}"
    
    if @employee.update(employee_params)
      puts "✅ SUCCESS: Employee updated! New title: #{@employee.reload.title}"
      # Check if we have a return path, otherwise default to employee show page
      return_path = params[:return_to].presence || employee_path(@employee)
      redirect_to return_path, notice: 'Employee updated successfully.'
    else
      puts "❌ FAILED: Update errors: #{@employee.errors.full_messages}"
      # CRITICAL FIX: Render the form with errors instead of redirecting
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    client_id = @employee.client_id
    @employee.destroy
    redirect_to dashboard_path(client_id: client_id), notice: 'Employee deleted successfully.'
  end

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

  # ===== STEP 4C: NEW IMPORT METHODS =====
  
  def import_form
    @client_id = params[:client_id]
    @client = Client.find(@client_id) if @client_id
    redirect_to dashboard_path, alert: 'Please select a client first.' unless @client
  end

  def import_employees
    @client_id = params[:client_id]
    @client = Client.find(@client_id) if @client_id
    
    unless @client
      redirect_to dashboard_path, alert: 'Please select a client first.'
      return
    end

    unless params[:file].present?
      redirect_to import_form_employees_path(client_id: @client_id), alert: 'Please select a file to import.'
      return
    end

    file = params[:file]
    
    # Validate file is CSV
    unless file.original_filename.downcase.end_with?('.csv')
      redirect_to import_form_employees_path(client_id: @client_id), alert: 'Please upload a CSV file.'
      return
    end

    begin
      import_results = process_csv_import(file, @client)
      
      if import_results[:errors].any?
        flash[:alert] = "Import completed with #{import_results[:errors].count} errors. #{import_results[:success_count]} employees imported successfully."
        flash[:import_errors] = import_results[:errors]
      else
        flash[:notice] = "Successfully imported #{import_results[:success_count]} employees!"
      end
      
    rescue => e
      Rails.logger.error "Import error: #{e.message}"
      flash[:alert] = "Import failed: #{e.message}"
    end
    
    redirect_to dashboard_path(client_id: @client_id)
  end

  private

  def set_employee
    @employee = Employee.find(params[:id])
  end

  def employee_params
    params.require(:employee).permit(
      # Basic Information
      :name, :title, :department, :hire_date, :employment_type, :status, :client_id,
      # Payroll Information  
      :salary, :hours_worked, :pay_frequency, :marital_status,
      # Contact Information
      :address, :phone, :email, :emergency_contact_name, :emergency_contact_phone,
      # Tax Information
      :ssn, :federal_withholding_allowances, :federal_additional_withholding,
      :state_withholding_allowances, :state_additional_withholding,
      # Banking Information (for future use)
      :bank_routing_number, :bank_account_number
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
    end
  end
  
  # ===== STEP 4C: NEW CSV IMPORT HELPER METHODS =====
  
  def process_csv_import(file, client)
    require 'csv'
    results = { success_count: 0, errors: [] }
    
    CSV.foreach(file.path, headers: true) do |row|
      row_number = $.  # CSV line number
      
      begin
        # Simple mapping - adjust column names as needed
        employee = Employee.new(
          client: client,
          name: row['Name']&.strip,
          title: row['Title']&.strip,
          salary: parse_salary(row['Salary']),
          hours_worked: row['Hours']&.to_f || 40,
          department: row['Department']&.strip,
          phone: row['Phone']&.strip,
          email: row['Email']&.strip,
          hire_date: parse_date(row['Hire Date']) || Date.current,
          employment_type: parse_employment_type(row['Employment Type']) || 'W2',
          status: parse_status(row['Status']) || 'active'
        )
        
        if employee.save
          results[:success_count] += 1
        else
          error_msg = "Row #{row_number}: #{employee.errors.full_messages.join(', ')}"
          results[:errors] << error_msg
        end
        
      rescue => e
        error_msg = "Row #{row_number}: #{e.message}"
        results[:errors] << error_msg
      end
    end
    
    results
  end
  
  def parse_salary(salary_str)
    return nil if salary_str.blank?
    # Remove currency symbols and commas
    cleaned = salary_str.to_s.gsub(/[\$,]/, '')
    cleaned.to_f if cleaned.match?(/^\d+\.?\d*$/)
  end
  
  def parse_date(date_str)
    return nil if date_str.blank?
    Date.parse(date_str.to_s) rescue nil
  end
  
  def parse_employment_type(type_str)
    return 'W2' if type_str.blank?
    type_str.to_s.upcase.include?('1099') ? '1099' : 'W2'
  end
  
  def parse_status(status_str)
    return 'active' if status_str.blank?
    status_str.to_s.downcase == 'inactive' ? 'inactive' : 'active'
  end
end