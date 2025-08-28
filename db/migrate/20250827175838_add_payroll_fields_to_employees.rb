class AddPayrollFieldsToEmployees < ActiveRecord::Migration[7.1]
  def change
    # Note: ssn and bank_account already exist, renaming for clarity
    rename_column :employees, :bank_account, :bank_account_number
    add_column :employees, :bank_routing_number, :text  # Will be encrypted
    add_column :employees, :hire_date, :date
    add_column :employees, :employment_type, :string, default: 'W2'  # W2 or 1099
    add_column :employees, :department, :string
    add_column :employees, :pay_frequency, :string, default: 'biweekly'  # weekly, biweekly, monthly, semimonthly
    add_column :employees, :status, :string, default: 'active'  # active, inactive
    add_column :employees, :federal_withholding_allowances, :integer, default: 0
    add_column :employees, :federal_additional_withholding, :decimal, precision: 8, scale: 2, default: 0.0
    add_column :employees, :state_withholding_allowances, :integer, default: 0
    add_column :employees, :state_additional_withholding, :decimal, precision: 8, scale: 2, default: 0.0
    add_column :employees, :marital_status, :string  # single, married_jointly, married_separately, head_of_household
    add_column :employees, :address, :text
    add_column :employees, :phone, :string
    add_column :employees, :emergency_contact_name, :string
    add_column :employees, :emergency_contact_phone, :string
    
    # Add index for common lookups
    add_index :employees, :status
    add_index :employees, :employment_type
    add_index :employees, :department
    add_index :employees, :pay_frequency
  end
end