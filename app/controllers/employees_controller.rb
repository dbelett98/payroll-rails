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
      puts "✅ SUCCESS: Employee updated!"
      
      return_to = params[:return_to].presence || dashboard_path(client_id: @employee.client_id)
      redirect_to return_to, notice: 'Employee updated successfully.'
    else
      puts "❌ FAILED: Update errors: #{@employee.errors.full_messages}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    client_id = @employee.client_id
    @employee.destroy
    redirect_to dashboard_path(client_id: client_id), notice: 'Employee deleted successfully.'
  end

  # ===== NEW IMPORT METHODS FOR STEP 5B =====

  def import_form
    @client_id = params[:client_id]
    @client = Client.find(@client_id) if @client_id
    redirect_to dashboard_path, alert: 'Please select a client first.' unless @client
  end

  def import_preview
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
      # Parse CSV for preview without saving
      @preview_data = parse_csv_for_preview(file, @client)
      @existing_employees = @client.employees.pluck(:name).map(&:downcase)
      
      # Detect duplicates
      @duplicate_warnings = detect_duplicates(@preview_data, @existing_employees)
      
      render :import_preview
    rescue => e
      redirect_to import_form_employees_path(client_id: @client_id), 
                  alert: "Error reading CSV file: #{e.message}"
    end
  end

  def import_employees
    @client_id = params[:client_id]
    @client = Client.find(@client_id) if @client_id
    
    unless @client
      redirect_to dashboard_path, alert: 'Please select a client first.'
      return
    end

    # Get selected employee indices from form
    selected_indices = params[:selected_employees]&.keys&.map(&:to_i) || []
    
    if selected_indices.empty?
      redirect_to import_form_employees_path(client_id: @client_id), 
                  alert: 'No employees selected for import.'
      return
    end

    # Recreate preview data and import only selected employees
    file_data = params[:csv_data] # We'll pass this in the form
    preview_data = JSON.parse(file_data) if file_data
    
    unless preview_data
      redirect_to import_form_employees_path(client_id: @client_id), 
                  alert: 'Import session expired. Please upload the file again.'
      return
    end

    import_results = import_selected_employees(preview_data, selected_indices, @client)
    
    if import_results[:errors].any?
      flash[:alert] = "Import completed with #{import_results[:errors].count} errors. #{import_results[:success_count]} employees imported successfully."
      flash[:import_errors] = import_results[:errors]
    else
      flash[:notice] = "Successfully imported #{import_results[:success_count]} employees!"
    end

    redirect_to dashboard_path(client_id: @client_id)
  end

  private

  def set_employee
    @employee = Employee.find(params[:id])
  end

  def employee_params
    params.require(:employee).permit(
      :client_id, :name, :title, :hours_worked, :salary, :phone, :email,
      :ssn, :routing_number, :account_number, :hire_date, :employment_type,
      :department, :pay_frequency, :status, :federal_withholding_allowances,
      :state_withholding_allowances, :federal_additional_withholding,
      :state_additional_withholding
    )
  end

  # ===== CSV IMPORT HELPER METHODS =====

  def parse_csv_for_preview(file, client)
    require 'csv'
    
    preview_data = []
    
    CSV.foreach(file.path, headers: true, header_converters: :symbol) do |row|
      employee_data = {
        name: row[:name]&.strip,
        title: row[:title]&.strip,
        salary: parse_salary(row[:salary]),
        hours_worked: row[:hours]&.to_f || 40,
        department: row[:department]&.strip,
        phone: row[:phone]&.strip,
        email: row[:email]&.strip,
        hire_date: parse_date(row[:hire_date]) || Date.current,
        employment_type: parse_employment_type(row[:employment_type]) || 'W2',
        status: parse_status(row[:status]) || 'active'
      }
      
      # Add validation info for preview
      employee_data[:valid] = validate_employee_data(employee_data)
      employee_data[:errors] = get_validation_errors(employee_data)
      
      preview_data << employee_data
    end
    
    preview_data
  end

  def detect_duplicates(preview_data, existing_employees)
    warnings = []
    
    # Check for duplicates within the CSV
    names_in_csv = preview_data.map { |emp| emp[:name]&.downcase }.compact
    duplicate_names_in_csv = names_in_csv.select { |name| names_in_csv.count(name) > 1 }.uniq
    
    duplicate_names_in_csv.each do |name|
      warnings << {
        type: 'csv_duplicate',
        message: "Multiple employees named '#{name.titleize}' found in CSV",
        name: name
      }
    end
    
    # Check for duplicates against existing database
    preview_data.each_with_index do |emp_data, index|
      name = emp_data[:name]&.downcase
      if existing_employees.include?(name)
        warnings << {
          type: 'database_duplicate',
          message: "Employee '#{name.titleize}' already exists in database",
          name: name,
          index: index
        }
      end
    end
    
    warnings
  end

  def import_selected_employees(preview_data, selected_indices, client)
    results = { success_count: 0, errors: [] }
    
    selected_indices.each do |index|
      next unless preview_data[index]
      
      employee_data = preview_data[index]
      
      begin
        # Parse hire_date safely
        hire_date = begin
          Date.parse(employee_data['hire_date'].to_s) if employee_data['hire_date']
        rescue
          Date.current
        end || Date.current
        
        employee = Employee.new(
          client: client,
          name: employee_data['name'],
          title: employee_data['title'],
          salary: employee_data['salary'],
          hours_worked: employee_data['hours_worked'],
          department: employee_data['department'],
          phone: employee_data['phone'],
          email: employee_data['email'],
          hire_date: hire_date,
          employment_type: employee_data['employment_type'],
          status: employee_data['status']
        )
        
        if employee.save
          results[:success_count] += 1
        else
          error_msg = "#{employee_data['name']}: #{employee.errors.full_messages.join(', ')}"
          results[:errors] << error_msg
        end
        
      rescue => e
        error_msg = "#{employee_data['name']}: #{e.message}"
        results[:errors] << error_msg
      end
    end
    
    results
  end

  def validate_employee_data(data)
    data[:name].present? && 
    data[:salary].present? && 
    data[:salary] > 0
  end

  def get_validation_errors(data)
    errors = []
    errors << "Name is required" if data[:name].blank?
    errors << "Salary is required" if data[:salary].blank?
    errors << "Salary must be greater than 0" if data[:salary].present? && data[:salary] <= 0
    errors
  end

  def parse_salary(salary_str)
    return nil if salary_str.blank?
    # Remove currency symbols and commas
    cleaned = salary_str.to_s.gsub(/[\$,]/, '')
    cleaned.to_f if cleaned.match?(/^\d+\.?\d*$/)
  end
  
  def parse_date(date_str)
    return nil if date_str.blank?
    begin
      Date.parse(date_str.to_s)
    rescue
      nil
    end
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