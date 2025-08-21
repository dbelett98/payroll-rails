class AddEmployeeIdToPayrollRuns < ActiveRecord::Migration[7.1]
  def change
    add_column :payroll_runs, :employee_id, :integer
    add_foreign_key :payroll_runs, :employees
  end
end