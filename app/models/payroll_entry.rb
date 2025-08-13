class PayrollEntry < ApplicationRecord
  belongs_to :employee
  belongs_to :payroll_run
end
