# app/models/client.rb: Enhanced client model with validations (free open-source ActiveRecord).
class Client < ApplicationRecord
  # Associations
  belongs_to :user  # Allows client.user (free).
  has_many :employees, dependent: :destroy  # Allows client.employees, destroys employees when client deleted (free).
  has_many :payroll_runs, dependent: :destroy  # Allows client.payroll_runs (free).

  # Simple backup validations (JavaScript will handle formatting)
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone, length: { maximum: 20 }, allow_blank: true
  validates :ein, length: { maximum: 15 }, allow_blank: true
  validates :bank_account, length: { maximum: 50 }, allow_blank: true
  validates :address, length: { maximum: 500 }, allow_blank: true

  # Clean and format data before saving
  before_save :format_fields

  private

  def format_fields
    # Remove all non-digits from EIN and reformat
    if ein.present?
      clean_ein = ein.gsub(/\D/, '')
      self.ein = clean_ein.length >= 9 ? "#{clean_ein[0,2]}-#{clean_ein[2,9]}" : clean_ein
    end
    
    # Remove all non-digits from phone and reformat
    if phone.present?
      clean_phone = phone.gsub(/\D/, '')
      if clean_phone.length == 10
        self.phone = "(#{clean_phone[0,3]}) #{clean_phone[3,3]}-#{clean_phone[6,4]}"
      end
    end
  end

  # Helper methods
  def total_employees
    employees.count
  end

  def total_payroll
    employees.sum(&:calculate_pay)
  end

  def display_info
    info = [name]
    info << "EIN: #{ein}" if ein.present?
    info << "#{employees.count} employees"
    info.join(" • ")
  end
end