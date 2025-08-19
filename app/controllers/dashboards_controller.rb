# app/controllers/dashboards_controller.rb: Handles dashboard with payroll (free open-source Rails controller).
class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def show
    @clients = current_user.clients
    @selected_client = Client.find_by(id: params[:client_id]) if params[:client_id]
    @employees = @selected_client ? @selected_client.employees : []
    @employees.each do |employee|
      employee.pay = employee.calculate_pay  # Calculate pay for display (free)
    end
  end
end