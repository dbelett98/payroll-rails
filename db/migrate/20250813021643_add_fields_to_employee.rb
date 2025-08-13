class AddFieldsToEmployee < ActiveRecord::Migration[7.1]
  def change
    add_column :employees, :hourly_rate, :decimal
    add_column :employees, :salary, :decimal
    add_reference :employees, :client, null: false, foreign_key: true
  end
end
