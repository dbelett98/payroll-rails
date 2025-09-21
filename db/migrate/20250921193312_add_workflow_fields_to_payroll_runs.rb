class AddWorkflowFieldsToPayrollRuns < ActiveRecord::Migration[7.1]
  def change
    # Pay period fields
    add_column :payroll_runs, :pay_period_start, :date
    add_column :payroll_runs, :pay_period_end, :date
    add_column :payroll_runs, :pay_frequency, :string
    
    # Audit trail fields
    add_column :payroll_runs, :status_changed_at, :datetime
    add_column :payroll_runs, :status_changed_by, :string
    add_column :payroll_runs, :notes, :text
    
    # Identification fields
    add_column :payroll_runs, :name, :string
    add_column :payroll_runs, :description, :text
    
    # Add indexes for performance
    add_index :payroll_runs, :status
    add_index :payroll_runs, :pay_frequency
    add_index :payroll_runs, :pay_period_start
    add_index :payroll_runs, :pay_period_end
    add_index :payroll_runs, [:client_id, :status]
  end
end