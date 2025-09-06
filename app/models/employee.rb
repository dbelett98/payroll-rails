# app/models/employee.rb - Complete replacement (Fixed encryption issue)

class Employee < ApplicationRecord
  belongs_to :client
  has_many :payroll_runs, dependent: :destroy
  
  encrypts :ssn, deterministic: false
  encrypts :bank_routing_number, deterministic: false  
  encrypts :bank_account_number, deterministic: false
  
  # NOTE: Removed encrypts for now - will add in Step M when we set up Rails credentials
  # encrypts :ssn
  # encrypts :bank_routing_number
  # ===== UPDATED VALIDATIONS - IMPORT FRIENDLY =====
  
  # Core required fields - only name is absolutely required
  validates :name, presence: { message: "is required" }, length: { minimum: 2, message: "must be at least 2 characters" }
  
  # Optional but validated when present
  validates :title, length: { minimum: 1, message: "cannot be blank if provided" }, allow_blank: true
  validates :salary, numericality: { greater_than: 0, message: "must be greater than $0" }, allow_blank: true
  validates :hours_worked, numericality: { greater_than_or_equal_to: 0, message: "cannot be negative" }, allow_blank: true
  validates :hire_date, presence: { message: "is recommended for payroll processing" }, allow_blank: true
  
  # Employment details with defaults
  validates :employment_type, inclusion: { in: %w[W2 1099], message: "must be W2 or 1099" }
  validates :status, inclusion: { in: %w[active inactive], message: "must be active or inactive" }
  validates :pay_frequency, inclusion: { 
    in: %w[weekly biweekly semimonthly monthly], 
    message: "must be weekly, biweekly, semimonthly, or monthly" 
  }
  
  # Optional fields with validation when present
  validates :marital_status, inclusion: { 
    in: %w[single married_jointly married_separately head_of_household], 
    message: "must be a valid marital status",
    allow_blank: true
  }
  
  # Contact validations - flexible format
  validates :phone, format: { 
    with: /\A[\+\-\s\(\)0-9]+\z/, 
    message: "contains invalid characters" 
  }, allow_blank: true
  
  validates :emergency_contact_phone, format: { 
    with: /\A[\+\-\s\(\)0-9]+\z/, 
    message: "contains invalid characters" 
  }, allow_blank: true
  
  validates :email, format: { 
    with: URI::MailTo::EMAIL_REGEXP, 
    message: "is not a valid email address" 
  }, allow_blank: true
  
  # SSN validation - flexible format (no encryption for now)
  validates :ssn, format: { 
    with: /\A\d{3}-?\d{2}-?\d{4}\z/, 
    message: "must be in format XXX-XX-XXXX or XXXXXXXXX" 
  }, allow_blank: true
  
  # Banking validations (when provided, no encryption for now)
  validates :bank_routing_number, format: { 
    with: /\A\d{9}\z/, 
    message: "must be exactly 9 digits" 
  }, allow_blank: true
  
  validates :bank_account_number, format: { 
    with: /\A\d{4,17}\z/, 
    message: "must be 4-17 digits" 
  }, allow_blank: true
  
  # Tax withholding validations
  validates :federal_withholding_allowances, numericality: { 
    greater_than_or_equal_to: 0, 
    message: "cannot be negative" 
  }, allow_blank: true
  
  validates :state_withholding_allowances, numericality: { 
    greater_than_or_equal_to: 0, 
    message: "cannot be negative" 
  }, allow_blank: true
  
  validates :federal_additional_withholding, numericality: { 
    greater_than_or_equal_to: 0, 
    message: "cannot be negative" 
  }, allow_blank: true
  
  validates :state_additional_withholding, numericality: { 
    greater_than_or_equal_to: 0, 
    message: "cannot be negative" 
  }, allow_blank: true

  # ===== NEW: DATA COMPLETION METHODS =====
  
  # Required fields for payroll processing
  PAYROLL_REQUIRED_FIELDS = %w[salary hours_worked hire_date].freeze
  CONTACT_REQUIRED_FIELDS = %w[phone email].freeze
  BANKING_REQUIRED_FIELDS = %w[bank_routing_number bank_account_number].freeze
  TAX_REQUIRED_FIELDS = %w[ssn].freeze
  
  # Check if employee has missing critical data
  def has_missing_required_data?
    missing_payroll_data? || missing_contact_data? || missing_tax_data?
  end
  
  # Check specific data categories
  def missing_payroll_data?
    PAYROLL_REQUIRED_FIELDS.any? { |field| send(field).blank? }
  end
  
  def missing_contact_data?
    CONTACT_REQUIRED_FIELDS.all? { |field| send(field).blank? }
  end
  
  def missing_banking_data?
    BANKING_REQUIRED_FIELDS.any? { |field| send(field).blank? }
  end
  
  def missing_tax_data?
    TAX_REQUIRED_FIELDS.any? { |field| send(field).blank? }
  end
  
  # Get list of missing required fields
  def missing_required_fields
    missing = []
    missing += missing_payroll_fields
    missing += missing_contact_fields if missing_contact_data?
    missing += missing_tax_fields
    missing
  end
  
  def missing_payroll_fields
    PAYROLL_REQUIRED_FIELDS.select { |field| send(field).blank? }
  end
  
  def missing_contact_fields
    return ['phone or email'] if missing_contact_data?
    []
  end
  
  def missing_tax_fields
    TAX_REQUIRED_FIELDS.select { |field| send(field).blank? }
  end
  
  # Data completion percentage
  def data_completion_percentage
    total_fields = PAYROLL_REQUIRED_FIELDS.count + 1 + TAX_REQUIRED_FIELDS.count # +1 for contact (either phone or email)
    completed_fields = total_fields - missing_required_fields.count
    ((completed_fields.to_f / total_fields) * 100).round
  end
  
  # Warning message for missing data
  def missing_data_warning
    return nil unless has_missing_required_data?
    
    missing = missing_required_fields
    case missing.count
    when 1
      "Missing: #{missing.first.humanize}"
    when 2
      "Missing: #{missing.first.humanize} and #{missing.last.humanize}"
    else
      "Missing: #{missing.count} required fields"
    end
  end
  
  # Calculate hourly rate from annual salary
  def calculate_hourly_rate
    return 0 if salary.blank?
    (salary / 2080.0).round(2) # Standard 40 hours/week * 52 weeks
  end
  
  # Calculate gross pay based on pay frequency
  def calculate_gross_pay_per_period
    return 0 if salary.blank?

    case pay_frequency
    when 'weekly'
      (salary / 52.0).round(2)
    when 'biweekly'
      (salary / 26.0).round(2)
    when 'semimonthly'
      (salary / 24.0).round(2)
    when 'monthly'
      (salary / 12.0).round(2)
    else
      0
    end
  end
  
  # Helper methods for display
  def full_name
    name
  end
  
  def display_name
    title.present? ? "#{name} - #{title}" : name
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
  
  # Formatted display methods (no encryption for now)
  def formatted_ssn
    return 'Not provided' if ssn.blank?
    "***-**-#{ssn.to_s.last(4)}"
  end
  
  def masked_ssn
    formatted_ssn
  end
  
  def formatted_phone
    return 'Not provided' if phone.blank?
    # Clean and format phone number
    digits = phone.gsub(/\D/, '')
    case digits.length
    when 10
      "(#{digits[0,3]}) #{digits[3,3]}-#{digits[6,4]}"
    when 11
      "+#{digits[0]} (#{digits[1,3]}) #{digits[4,3]}-#{digits[7,4]}"
    else
      phone
    end
  end
  
  def formatted_emergency_contact_phone
    return 'Not provided' if emergency_contact_phone.blank?
    digits = emergency_contact_phone.gsub(/\D/, '')
    case digits.length
    when 10
      "(#{digits[0,3]}) #{digits[3,3]}-#{digits[6,4]}"
    when 11
      "+#{digits[0]} (#{digits[1,3]}) #{digits[4,3]}-#{digits[7,4]}"
    else
      emergency_contact_phone
    end
  end
  
  def masked_bank_account
    return 'Not provided' if bank_account_number.blank?
    "*" * ([bank_account_number.to_s.length - 4, 1].max) + bank_account_number.to_s.last(4)
  end
  
  def masked_routing_number
    return 'Not provided' if bank_routing_number.blank?
    "*****#{bank_routing_number.to_s.last(4)}"
  end
  
  # Date and time calculations
  def employment_length_in_years
    return 0 if hire_date.blank?
    ((Date.current - hire_date) / 365.25).round(1)
  end
  
  def employment_length_display
    return 'Not specified' if hire_date.blank?
    years = employment_length_in_years
    if years < 1
      months = ((Date.current - hire_date) / 30).round
      "#{months} #{'month'.pluralize(months)}"
    else
      "#{years} #{'year'.pluralize(years.to_i)}"
    end
  end
  
  def next_pay_date
    return nil if hire_date.blank?
    
    base_date = hire_date
    today = Date.current
    
    case pay_frequency
    when 'weekly'
      # Find next Friday
      days_until_friday = (5 - today.wday) % 7
      days_until_friday = 7 if days_until_friday == 0
      today + days_until_friday.days
    when 'biweekly'
      # Every other Friday
      days_since_hire = (today - base_date).to_i
      weeks_since_hire = (days_since_hire / 7).to_i
      biweeks_since_hire = weeks_since_hire / 2
      next_biweek = biweeks_since_hire + 1
      base_date + (next_biweek * 2).weeks
    when 'semimonthly'
      # 15th and last day of month
      if today.day <= 15
        Date.new(today.year, today.month, 15)
      else
        today.end_of_month
      end
    when 'monthly'
      # Same day each month as hire date
      target_day = [hire_date.day, today.end_of_month.day].min
      if today.day <= target_day
        Date.new(today.year, today.month, target_day)
      else
        next_month = today.next_month
        Date.new(next_month.year, next_month.month, [hire_date.day, next_month.end_of_month.day].min)
      end
    else
      nil
    end
  end
  
  # Status and type display methods
  def status_display
    status&.titleize || 'Active'
  end
  
  def employment_type_display
    case employment_type
    when 'W2'
      'W2 Employee'
    when '1099'
      '1099 Contractor'
    else
      'W2 Employee'
    end
  end
  
  def pay_frequency_display
    pay_frequency&.titleize&.gsub('biweekly', 'Bi-weekly') || 'Bi-weekly'
  end
  
  def marital_status_display
    case marital_status
    when 'single'
      'Single'
    when 'married_jointly'
      'Married Filing Jointly'
    when 'married_separately'
      'Married Filing Separately'
    when 'head_of_household'
      'Head of Household'
    else
      'Not specified'
    end
  end

  # ===== CLASS METHODS =====
  
  def self.total_payroll_cost(client_id = nil)
    employees = client_id ? where(client_id: client_id) : all
    employees.active.sum { |emp| emp.calculate_pay }
  end

  def self.by_pay_frequency_stats
    active.group(:pay_frequency).count
  end

  def self.by_employment_type_stats
    active.group(:employment_type).count
  end
  
  def self.by_department_stats
    active.group(:department).count
  end
  
  def self.average_salary(client_id = nil)
    employees = client_id ? where(client_id: client_id) : all
    employees.active.average(:salary)&.round(2) || 0
  end

  # ===== CONSTANTS FOR DROPDOWNS =====
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
  
  # ===== CALLBACKS =====
  
  # Set defaults before validation
  before_validation :set_defaults, on: :create
  
  # Clean phone numbers before saving
  before_save :clean_phone_numbers
  
  private
  
  def set_defaults
    self.employment_type ||= 'W2'
    self.pay_frequency ||= 'biweekly'
    self.status ||= 'active'
    self.federal_withholding_allowances ||= 0
    self.state_withholding_allowances ||= 0
    self.federal_additional_withholding ||= 0.0
    self.state_additional_withholding ||= 0.0
    self.hire_date ||= Date.current if hire_date.blank?
  end
  
  def clean_phone_numbers
    # Remove any non-digits from phone numbers before saving
    self.phone = phone.gsub(/\D/, '') if phone.present?
    self.emergency_contact_phone = emergency_contact_phone.gsub(/\D/, '') if emergency_contact_phone.present?
  end
end