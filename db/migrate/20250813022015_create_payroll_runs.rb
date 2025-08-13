class CreatePayrollRuns < ActiveRecord::Migration[7.1]
  def change
    create_table :payroll_runs do |t|
      t.datetime :run_date
      t.decimal :total_gross
      t.decimal :total_net
      t.decimal :taxes_withheld
      t.string :status
      t.references :client, null: false, foreign_key: true

      t.timestamps
    end
  end
end
