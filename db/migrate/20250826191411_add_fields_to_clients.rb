# Create this file: db/migrate/20250826000001_add_fields_to_clients.rb
class AddFieldsToClients < ActiveRecord::Migration[7.1]
  def change
    add_column :clients, :ein, :string
    add_column :clients, :address, :text
    add_column :clients, :phone, :string
    add_column :clients, :email, :string
  end
end