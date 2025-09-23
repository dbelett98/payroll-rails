# db/migrate/20250923180024_add_status_tracking_to_payroll_runs.rb
class AddStatusTrackingToPayrollRuns < ActiveRecord::Migration[7.0]
  def change
    # Only add columns if they don't exist
    add_column :payroll_runs, :notes, :text unless column_exists?(:payroll_runs, :notes)
    
    # Add indexes for performance
    add_index :payroll_runs, :status unless index_exists?(:payroll_runs, :status)
    add_index :payroll_runs, :pay_frequency unless index_exists?(:payroll_runs, :pay_frequency)
    add_index :payroll_runs, [:client_id, :status] unless index_exists?(:payroll_runs, [:client_id, :status])
    add_index :payroll_runs, :created_at unless index_exists?(:payroll_runs, :created_at)
  end
end