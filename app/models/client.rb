# app/models/client.rb: Client model with associations (free open-source ActiveRecord).
class Client < ApplicationRecord
  # Associations
  belongs_to :user  # Allows client.user (free).
  has_many :employees, dependent: :destroy  # Allows client.employees (free).
  has_many :payroll_runs, dependent: :destroy  # Allows client.payroll_runs (free).

  validates :name, presence: true  # Basic validation (free).
end