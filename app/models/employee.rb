# app/models/employee.rb: Employee model with payroll logic (free open-source ActiveRecord).
class Employee < ApplicationRecord
  belongs_to :client
  has_many :payroll_runs, dependent: :destroy

  validates :name, presence: true
  validates :hours_worked, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :salary, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  def calculate_pay
    (hours_worked || 0) * (salary || 0) / 2080.0  # Annual salary to hourly rate approximation
  end
end