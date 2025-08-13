class CreateEmployees < ActiveRecord::Migration[7.1]
  def change
    create_table :employees do |t|
      t.string :name
      t.string :ssn
      t.string :bank_account

      t.timestamps
    end
  end
end
