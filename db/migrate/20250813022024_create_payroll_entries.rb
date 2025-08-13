class CreatePayrollEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :payroll_entries do |t|
      t.decimal :hours_worked
      t.decimal :gross_pay
      t.decimal :deductions
      t.decimal :net_pay
      t.references :employee, null: false, foreign_key: true
      t.references :payroll_run, null: false, foreign_key: true

      t.timestamps
    end
  end
end
