# Create this migration by running:
# bundle exec rails generate migration AddStepLFieldsToEmployees

class AddStepLFieldsToEmployees < ActiveRecord::Migration[7.1]
  def up
    # Add columns that may not exist yet
    add_column :employees, :hire_date, :date unless column_exists?(:employees, :hire_date)
    add_column :employees, :employment_type, :string, default: 'W2' unless column_exists?(:employees, :employment_type)
    add_column :employees, :department, :string unless column_exists?(:employees, :department)
    add_column :employees, :pay_frequency, :string, default: 'biweekly' unless column_exists?(:employees, :pay_frequency)
    add_column :employees, :status, :string, default: 'active' unless column_exists?(:employees, :status)
    add_column :employees, :marital_status, :string unless column_exists?(:employees, :marital_status)
    add_column :employees, :address, :text unless column_exists?(:employees, :address)
    add_column :employees, :email, :string unless column_exists?(:employees, :email)
    
    # Emergency contact fields
    add_column :employees, :emergency_contact_name, :string unless column_exists?(:employees, :emergency_contact_name)
    add_column :employees, :emergency_contact_phone, :string unless column_exists?(:employees, :emergency_contact_phone)
    
    # Federal tax withholding fields
    add_column :employees, :federal_withholding_allowances, :integer, default: 0 unless column_exists?(:employees, :federal_withholding_allowances)
    add_column :employees, :federal_additional_withholding, :decimal, precision: 8, scale: 2, default: 0.0 unless column_exists?(:employees, :federal_additional_withholding)
    
    # State tax withholding fields
    add_column :employees, :state_withholding_allowances, :integer, default: 0 unless column_exists?(:employees, :state_withholding_allowances)
    add_column :employees, :state_additional_withholding, :decimal, precision: 8, scale: 2, default: 0.0 unless column_exists?(:employees, :state_additional_withholding)
    
    # Banking fields (for future use - Step M/N)
    add_column :employees, :bank_account_number, :string unless column_exists?(:employees, :bank_account_number)
    add_column :employees, :bank_routing_number, :string unless column_exists?(:employees, :bank_routing_number)
    
    # Add indexes for performance
    add_index :employees, :employment_type unless index_exists?(:employees, :employment_type)
    add_index :employees, :status unless index_exists?(:employees, :status)
    add_index :employees, :department unless index_exists?(:employees, :department)
    add_index :employees, :pay_frequency unless index_exists?(:employees, :pay_frequency)
    add_index :employees, :hire_date unless index_exists?(:employees, :hire_date)
  end

  def down
    # Remove indexes first
    remove_index :employees, :employment_type if index_exists?(:employees, :employment_type)
    remove_index :employees, :status if index_exists?(:employees, :status)
    remove_index :employees, :department if index_exists?(:employees, :department)
    remove_index :employees, :pay_frequency if index_exists?(:employees, :pay_frequency)
    remove_index :employees, :hire_date if index_exists?(:employees, :hire_date)
    
    # Remove columns (be careful with this in production!)
    remove_column :employees, :hire_date if column_exists?(:employees, :hire_date)
    remove_column :employees, :employment_type if column_exists?(:employees, :employment_type)
    remove_column :employees, :department if column_exists?(:employees, :department)
    remove_column :employees, :pay_frequency if column_exists?(:employees, :pay_frequency)
    remove_column :employees, :status if column_exists?(:employees, :status)
    remove_column :employees, :marital_status if column_exists?(:employees, :marital_status)
    remove_column :employees, :address if column_exists?(:employees, :address)
    remove_column :employees, :email if column_exists?(:employees, :email)
    remove_column :employees, :emergency_contact_name if column_exists?(:employees, :emergency_contact_name)
    remove_column :employees, :emergency_contact_phone if column_exists?(:employees, :emergency_contact_phone)
    remove_column :employees, :federal_withholding_allowances if column_exists?(:employees, :federal_withholding_allowances)
    remove_column :employees, :federal_additional_withholding if column_exists?(:employees, :federal_additional_withholding)
    remove_column :employees, :state_withholding_allowances if column_exists?(:employees, :state_withholding_allowances)
    remove_column :employees, :state_additional_withholding if column_exists?(:employees, :state_additional_withholding)
    remove_column :employees, :bank_account_number if column_exists?(:employees, :bank_account_number)
    remove_column :employees, :bank_routing_number if column_exists?(:employees, :bank_routing_number)
  end
end