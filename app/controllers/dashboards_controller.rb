# app/controllers/dashboards_controller.rb: Handles dashboard with payroll (free open-source Rails controller).
class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def show
    @clients = current_user.clients
    puts "Current User Clients: #{@clients.inspect}"  # Debug: Print clients to console (free Ruby method).
    @selected_client = Client.find_by(id: params[:client_id]) if params[:client_id].present?
    # Default to first client if no selection and clients exist
    @selected_client ||= @clients.first
    @employees = @selected_client ? @selected_client.employees : []
    puts "Selected Client: #{@selected_client.inspect}"  # Debug: Print selected client.
    puts "Employees: #{@employees.inspect}"  # Debug: Print employees.
    @new_employee = Employee.new  # Initialize new employee for form (free).
  end
end