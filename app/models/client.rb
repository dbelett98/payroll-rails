# app/models/client.rb: Enhanced client model with validations (free open-source ActiveRecord).
class Client < ApplicationRecord
  # Associations
  belongs_to :user  # Allows client.user (free).
  has_many :employees, dependent: :destroy  # Allows client.employees, destroys employees when client deleted (free).
  has_many :payroll_runs, dependent: :destroy  # Allows client.payroll_runs (free).

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone, format: { with: /\A[\d\-\(\)\+\s\.]+\z/ }, allow_blank: true
  validates :ein, format: { with: /\A\d{2}-\d{7}\z/ }, allow_blank: true
  validates :bank_account, length: { maximum: 50 }, allow_blank: true
  validates :address, length: { maximum: 500 }, allow_blank: true

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