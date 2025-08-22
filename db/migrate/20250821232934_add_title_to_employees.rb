class AddTitleToEmployees < ActiveRecord::Migration[7.1]
  def change
    add_column :employees, :title, :string
  end
end
