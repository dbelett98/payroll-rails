# app/models/payroll_entry.rb - Enhanced for Step O2 Completion
class PayrollEntry < ApplicationRecord
  belongs_to :employee
  belongs_to :payroll_run
  
  # ===== VALIDATIONS =====
  validates :gross_pay, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :net_pay, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :hours_worked, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :pay_rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  # Ensure one entry per employee per payroll run
  validates :employee_id, uniqueness: { scope: :payroll_run_id, message: "already included in this payroll run" }
  
  # ===== INSTANCE METHODS =====
  
  # Calculate total deductions (gross - net)
  def total_deductions
    gross_pay - net_pay
  end
  
  # Display employee name for this entry
  def employee_name
    employee&.name || 'Unknown Employee'
  end
  
  # Get employee title
  def employee_title
    employee&.title || 'No Title'
  end
  
  # Get employee department
  def employee_department
    employee&.department || 'No Department'
  end
  
  # Check if this is overtime hours
  def has_overtime?
    return false unless hours_worked && employee&.employment_type == 'W2'
    
    # Standard overtime threshold
    overtime_threshold = case payroll_run&.pay_frequency
                        when 'weekly' then 40.0
                        when 'biweekly' then 80.0
                        when 'monthly' then 173.33
                        else 80.0
                        end
    
    hours_worked > overtime_threshold
  end
  
  # Calculate regular hours
  def regular_hours
    return hours_worked unless has_overtime?
    
    overtime_threshold = case payroll_run&.pay_frequency
                        when 'weekly' then 40.0
                        when 'biweekly' then 80.0
                        when 'monthly' then 173.33
                        else 80.0
                        end
    
    [hours_worked, overtime_threshold].min
  end
  
  # Calculate overtime hours
  def overtime_hours
    return 0.0 unless has_overtime?
    
    overtime_threshold = case payroll_run&.pay_frequency
                        when 'weekly' then 40.0
                        when 'biweekly' then 80.0
                        when 'monthly' then 173.33
                        else 80.0
                        end
    
    [hours_worked - overtime_threshold, 0.0].max
  end
  
  # Get the pay rate for this employee from the PayrollRun creation
  def pay_rate
    # For 1099 contractors, use their hourly rate
    if employee&.employment_type == '1099'
      employee.calculate_hourly_rate
    else
      # For W2 employees, use their annual salary
      employee.salary || 0
    end
  end

  # Calculate hourly rate from annual salary
  def hourly_rate
    return pay_rate if employee&.employment_type == '1099'
    return 0.0 unless employee&.salary.present?
    
    (employee.salary / 2080.0).round(2) # 40 hours/week * 52 weeks
  end
  
  # Format pay period for display
  def pay_period_display
    payroll_run&.pay_period_display || 'Not Set'
  end
  
  # Get client name
  def client_name
    payroll_run&.client&.name || 'Unknown Client'
  end
  
  # ===== CALCULATION METHODS (Will be enhanced in Step O4) =====
  
  # Recalculate gross pay based on current employee data
  def recalculate_gross_pay!
    return false unless employee
    
    new_gross = employee.calculate_pay
    update!(gross_pay: new_gross)
    new_gross
  end
  
  # Recalculate net pay (placeholder for Step O4)
  def recalculate_net_pay!
    # For now, net pay = gross pay
    # In Step O4, this will include tax calculations
    update!(net_pay: gross_pay)
    net_pay
  end
  
  # Get pay breakdown (for detailed pay stub view)
  def pay_breakdown
    {
      employee_name: employee_name,
      hours_worked: hours_worked,
      regular_hours: regular_hours,
      overtime_hours: overtime_hours,
      hourly_rate: hourly_rate,
      gross_pay: gross_pay,
      total_deductions: total_deductions,
      net_pay: net_pay,
      pay_period: pay_period_display
    }
  end
  
  # ===== DISPLAY METHODS =====
  
  def status_display
    payroll_run&.status_display || 'Draft'
  end
  
  def formatted_gross_pay
    "$#{gross_pay.round(2)}"
  end
  
  def formatted_net_pay
    "$#{net_pay.round(2)}"
  end
  
  def formatted_deductions
    "$#{total_deductions.round(2)}"
  end
  
  # ===== CLASS METHODS =====
  
  # Create entry with automatic calculations
  def self.create_for_employee!(payroll_run, employee)
    create!(
      payroll_run: payroll_run,
      employee: employee,
      gross_pay: employee.calculate_pay,
      net_pay: employee.calculate_pay, # Will be enhanced in Step O4
      hours_worked: employee.hours_worked || 0,
      pay_rate: employee.salary || 0
    )
  end
  
  # Get entries for a specific client
  def self.for_client(client)
    joins(payroll_run: :client).where(clients: { id: client.id })
  end
  
  # Get entries for a specific employee
  def self.for_employee(employee)
    where(employee: employee)
  end
  
  # ===== SCOPES =====
  scope :recent, -> { joins(:payroll_run).order('payroll_runs.created_at DESC') }
  scope :by_status, ->(status) { joins(:payroll_run).where(payroll_runs: { status: status }) }
  scope :processed, -> { joins(:payroll_run).where(payroll_runs: { status: 'processed' }) }
  scope :with_overtime, -> { where('hours_worked > ?', 40) }
  
  # ===== CALLBACKS =====
  before_save :ensure_net_pay_not_greater_than_gross
  after_create :log_creation
  after_update :log_update
  
  private
  
  def ensure_net_pay_not_greater_than_gross
    if net_pay > gross_pay
      self.net_pay = gross_pay
    end
  end
  
  def log_creation
    Rails.logger.info "PayrollEntry created: #{employee_name} - $#{gross_pay} for #{payroll_run&.display_name}"
  end
  
  def log_update
    Rails.logger.info "PayrollEntry updated: #{employee_name} - $#{gross_pay} for #{payroll_run&.display_name}"
  end
end