class Employee < ApplicationRecord
  belongs_to :client
  has_many :payroll_runs, dependent: :destroy
  
  # Encrypted attributes for sensitive data (ssn already exists)
  encrypts :ssn
  encrypts :bank_routing_number
  encrypts :bank_account_number
  
  # Validations
  validates :name, presence: true, length: { minimum: 2 }
  validates :hours_worked, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :salary, presence: true, numericality: { greater_than: 0 }
  validates :title, presence: true
  validates :hire_date, presence: true
  validates :employment_type, inclusion: { in: %w[W2 1099], message: "must be W2 or 1099" }
  validates :status, inclusion: { in: %w[active inactive], message: "must be active or inactive" }
  validates :pay_frequency, inclusion: { 
    in: %w[weekly biweekly semimonthly monthly], 
    message: "must be weekly, biweekly, semimonthly, or monthly" 
  }
  validates :marital_status, inclusion: { 
    in: %w[single married_jointly married_separately head_of_household], 
    message: "must be valid marital status",
    allow_blank: true
  }
  
  # SSN validation (if provided)
  validates :ssn, format: { 
    with: /\A\d{3}-\d{2}-\d{4}\z/, 
    message: "must be in format XXX-XX-XXXX" 
  }, allow_blank: true
  
  # Bank account validations (if provided)
  validates :bank_routing_number, format: { 
    with: /\A\d{9}\z/, 
    message: "must be 9 digits" 
  }, allow_blank: true
  validates :bank_account_number, format: { 
    with: /\A\d{4,17}\z/, 
    message: "must be 4-17 digits" 
  }, allow_blank: true
  
  # Phone validations
  validates :phone, format: { 
    with: /\A\(\d{3}\) \d{3}-\d{4}\z/, 
    message: "must be in format (XXX) XXX-XXXX" 
  }, allow_blank: true
  validates :emergency_contact_phone, format: { 
    with: /\A\(\d{3}\) \d{3}-\d{4}\z/, 
    message: "must be in format (XXX) XXX-XXXX" 
  }, allow_blank: true
  
  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
  scope :w2_employees, -> { where(employment_type: 'W2') }
  scope :contractors, -> { where(employment_type: '1099') }
  scope :by_department, ->(dept) { where(department: dept) }
  scope :by_pay_frequency, ->(freq) { where(pay_frequency: freq) }
  
  # Existing calculation method (from previous steps)
  def calculate_pay
    # Basic calculation - will be enhanced in Step N
    if employment_type == '1099'
      # 1099 contractors - simple hourly calculation
      hours_worked * (salary / 2080) # Assume salary is annual, convert to hourly
    else
      # W2 employees - calculate with overtime
      regular_hours = [hours_worked, 40].min
      overtime_hours = [hours_worked - 40, 0].max
      hourly_rate = salary / 2080 # Convert annual salary to hourly
      
      (regular_hours * hourly_rate) + (overtime_hours * hourly_rate * 1.5)
    end
  end
  
  # Helper methods
  def full_name
    name
  end
  
  def active?
    status == 'active'
  end
  
  def w2_employee?
    employment_type == 'W2'
  end
  
  def contractor?
    employment_type == '1099'
  end
  
  def has_direct_deposit?
    bank_routing_number.present? && bank_account_number.present?
  end
  
  def masked_ssn
    return 'Not provided' if ssn.blank?
    "***-**-#{ssn.last(4)}"
  end
  
  def masked_bank_account
    return 'Not provided' if bank_account_number.blank?
    "*" * (bank_account_number.length - 4) + bank_account_number.last(4)
  end
  
  def employment_length_in_years
    return 0 if hire_date.blank?
    ((Date.current - hire_date) / 365.25).round(1)
  end
  
  def next_pay_date
    # Simple calculation - will be enhanced in Step O (Payroll Run Management)
    case pay_frequency
    when 'weekly'
      1.week.from_now.end_of_week
    when 'biweekly'
      2.weeks.from_now.end_of_week
    when 'semimonthly'
      Date.current.day <= 15 ? Date.current.end_of_month : Date.current.next_month.beginning_of_month + 14.days
    when 'monthly'
      Date.current.end_of_month
    end
  end
  
  # Constants for dropdowns
  EMPLOYMENT_TYPES = [
    ['W2 Employee', 'W2'],
    ['1099 Contractor', '1099']
  ].freeze
  
  PAY_FREQUENCIES = [
    ['Weekly', 'weekly'],
    ['Bi-Weekly', 'biweekly'],
    ['Semi-Monthly', 'semimonthly'],
    ['Monthly', 'monthly']
  ].freeze
  
  MARITAL_STATUSES = [
    ['Single', 'single'],
    ['Married Filing Jointly', 'married_jointly'],
    ['Married Filing Separately', 'married_separately'],
    ['Head of Household', 'head_of_household']
  ].freeze
  
  STATUSES = [
    ['Active', 'active'],
    ['Inactive', 'inactive']
  ].freeze
end