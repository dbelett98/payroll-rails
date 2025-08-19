class AddHoursWorkedToEmployees < ActiveRecord::Migration[7.1]
  def change
    add_column :employees, :hours_worked, :decimal
  end
end
