# app/models/payroll_run.rb - Enhanced with Employee Totals and Calculations
class PayrollRun < ApplicationRecord
  belongs_to :client
  has_many :payroll_entries, dependent: :destroy
  has_many :employees, through: :payroll_entries
  
  # ===== VALIDATIONS =====
  validates :status, inclusion: { 
    in: %w[draft review approved processed voided], 
    message: "must be draft, review, approved, processed, or voided" 
  }
  
  validates :name, presence: true, length: { maximum: 255 }
  validates :run_date, presence: true
  validates :pay_period_start, :pay_period_end, presence: true
  
  # Custom validation to ensure pay period makes sense
  validate :pay_period_end_after_start
  
  # ===== STATUS WORKFLOW =====
  STATUSES = %w[draft review approved processed voided].freeze
  
  VALID_TRANSITIONS = {
    'draft' => %w[review voided],
    'review' => %w[draft approved voided],
    'approved' => %w[processed voided],
    'processed' => %w[voided],
    'voided' => []
  }.freeze
  
  # Status check methods
  def draft?
    status == 'draft'
  end
  
  def review?
    status == 'review'
  end
  
  def approved?
    status == 'approved'
  end
  
  def processed?
    status == 'processed'
  end
  
  def voided?
    status == 'voided'
  end
  
  def can_transition_to?(new_status)
    VALID_TRANSITIONS[status]&.include?(new_status.to_s) || false
  end
  
  def transition_to!(new_status, user = nil)
    new_status = new_status.to_s
    
    unless can_transition_to?(new_status)
      raise "Cannot transition from #{status} to #{new_status}"
    end
    
    self.status = new_status
    self.status_changed_by = user&.email if user
    self.status_changed_at = Time.current
    save!
  end
  
  # ===== CALCULATION METHODS =====
  
  # Calculate total gross pay for all employees in this run
  def total_gross
    payroll_entries.sum(:gross_pay) || 0.0
  end
  
  # Calculate total net pay for all employees in this run
  def total_net
    payroll_entries.sum(:net_pay) || 0.0
  end
  
  # Calculate total hours for all employees in this run
  def total_hours
    payroll_entries.sum(:hours_worked) || 0.0
  end
  
  # Get employee count
  def employee_count
    payroll_entries.count
  end
  
  # Calculate total taxes withheld (will be enhanced in Step O4)
  def total_taxes
    total_gross - total_net
  end
  
  # Get average pay per employee
  def average_gross_pay
    return 0.0 if employee_count == 0
    (total_gross / employee_count).round(2)
  end
  
  # ===== DISPLAY METHODS =====
  
  def display_name
    name.present? ? name : "Payroll Run ##{id}"
  end
  
  def pay_period_display
    if pay_period_start && pay_period_end
      "#{pay_period_start.strftime('%m/%d/%Y')} - #{pay_period_end.strftime('%m/%d/%Y')}"
    else
      'Date range not set'
    end
  end
  
  def editable?
    draft? || review?
  end
  
  def status_badge_class
    case status
    when 'draft' then 'status-draft'
    when 'review' then 'status-review'
    when 'approved' then 'status-approved'
    when 'processed' then 'status-processed'
    when 'voided' then 'status-voided'
    else 'status-draft'
    end
  end
  
  def status_display
    status&.titleize || 'Draft'
  end
  
  def frequency_display
    pay_frequency&.titleize&.gsub('biweekly', 'Bi-weekly') || 'Not Set'
  end
  
  # ===== EMPLOYEE MANAGEMENT =====
  
  # Get employees by status
  def active_employees
    employees.where(status: 'active')
  end
  
  def inactive_employees  
    employees.where(status: 'inactive')
  end
  
  # Check if employee is included in this run
  def includes_employee?(employee)
    employees.include?(employee)
  end
  
  # Add employee to payroll run (creates PayrollEntry)
  def add_employee!(employee)
    return false if includes_employee?(employee)
    
    payroll_entries.create!(
      employee: employee,
      gross_pay: employee.calculate_pay,
      net_pay: employee.calculate_pay, # Will be enhanced in Step O4 with tax calculations
      hours_worked: employee.hours_worked || 0,
      pay_rate: employee.salary || 0
    )
  end
  
  # Remove employee from payroll run
  def remove_employee!(employee)
    payroll_entries.where(employee: employee).destroy_all
  end
  
  # ===== VALIDATION METHODS =====
  
  # Check if payroll run is ready for processing
  def ready_for_processing?
    return false unless approved?
    return false if employee_count == 0
    return false unless pay_period_start && pay_period_end
    return false unless run_date
    true
  end
  
  # Get validation errors for processing
  def processing_errors
    errors = []
    errors << "No employees selected" if employee_count == 0
    errors << "Pay period dates not set" unless pay_period_start && pay_period_end
    errors << "Run date not set" unless run_date
    errors << "Must be approved before processing" unless approved?
    errors
  end
  
  # ===== CLASS METHODS =====
  
  # Create payroll run with default settings
  def self.create_for_pay_frequency(client, pay_frequency, run_date = nil)
    run_date ||= Date.current
    start_date, end_date = calculate_pay_period(pay_frequency, run_date)
    
    create!(
      client: client,
      pay_frequency: pay_frequency,
      run_date: run_date,
      pay_period_start: start_date,
      pay_period_end: end_date,
      status: 'draft',
      name: "#{pay_frequency.titleize} Payroll - #{run_date.strftime('%b %Y')}"
    )
  end
  
  # Calculate pay period dates based on frequency
  def self.calculate_pay_period(frequency, run_date)
    case frequency
    when 'weekly'
      start_date = run_date.beginning_of_week
      end_date = run_date.end_of_week
    when 'biweekly'
      end_date = run_date
      start_date = run_date - 13.days
    when 'monthly'
      start_date = run_date.beginning_of_month
      end_date = run_date.end_of_month
    when 'semimonthly'
      if run_date.day <= 15
        start_date = run_date.beginning_of_month
        end_date = Date.new(run_date.year, run_date.month, 15)
      else
        start_date = Date.new(run_date.year, run_date.month, 16)
        end_date = run_date.end_of_month
      end
    else
      end_date = run_date
      start_date = run_date - 13.days
    end
    
    [start_date, end_date]
  end
  
  # ===== SCOPES =====
  scope :by_status, ->(status) { where(status: status) }
  scope :by_client, ->(client) { where(client: client) }
  scope :by_frequency, ->(frequency) { where(pay_frequency: frequency) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_period, ->(start_date, end_date) { where(run_date: start_date..end_date) }
  
  # ===== CALLBACKS =====
  before_validation :set_defaults, on: :create
  before_validation :normalize_pay_frequency
  after_create :log_creation
  
  private
  
  def set_defaults
    self.status ||= 'draft'
    self.run_date ||= Date.current
    
    if pay_frequency.present? && (pay_period_start.blank? || pay_period_end.blank?)
      self.pay_period_start, self.pay_period_end = self.class.calculate_pay_period(pay_frequency, run_date)
    end
    
    # Set default name if not provided
    if name.blank? && pay_frequency.present?
      self.name = "#{pay_frequency.titleize} Payroll - #{run_date.strftime('%b %Y')}"
    end
  end
  
  def normalize_pay_frequency
    self.pay_frequency = pay_frequency&.downcase
  end
  
  def pay_period_end_after_start
    return unless pay_period_start && pay_period_end
    
    if pay_period_end <= pay_period_start
      errors.add(:pay_period_end, "must be after pay period start")
    end
  end
  
  def log_creation
    Rails.logger.info "PayrollRun created: #{display_name} for #{client.name}"
  end
end