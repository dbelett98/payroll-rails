# app/models/payroll_run.rb - Fixed syntax
class PayrollRun < ApplicationRecord
  belongs_to :client
  has_many :payroll_entries, dependent: :destroy
  has_many :employees, through: :payroll_entries
  
  # ===== VALIDATIONS =====
  validates :status, inclusion: { 
    in: %w[draft review approved processed voided], 
    message: "must be draft, review, approved, processed, or voided" 
  }
  
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
    save!
  end
  
  # ===== INSTANCE METHODS =====
  def display_name
    "Payroll Run ##{id} - #{pay_period_display}"
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
  
  # ===== CLASS METHODS =====
  def self.create_for_pay_frequency(client, pay_frequency, run_date = nil)
    run_date ||= Date.current
    start_date, end_date = calculate_pay_period(pay_frequency, run_date)
    
    create!(
      client: client,
      pay_frequency: pay_frequency,
      run_date: run_date,
      pay_period_start: start_date,
      pay_period_end: end_date,
      status: 'draft'
    )
  end
  
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
    else
      end_date = run_date
      start_date = run_date - 13.days
    end
    
    [start_date, end_date]
  end
  
  # ===== CALLBACKS =====
  before_validation :set_defaults, on: :create
  
  private
  
  def set_defaults
    self.status ||= 'draft'
    self.run_date ||= Date.current
    
    if pay_frequency.present? && (pay_period_start.blank? || pay_period_end.blank?)
      self.pay_period_start, self.pay_period_end = self.class.calculate_pay_period(pay_frequency, run_date)
    end
  end
end