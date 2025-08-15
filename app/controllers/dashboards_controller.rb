# app/controllers/dashboards_controller.rb: Handles dashboard for staff and admin (free open-source Rails controller).
class DashboardsController < ApplicationController
  before_action :authenticate_user!  # Free Devise auth.

  def show
    @clients = current_user.clients  # Fetch clients for logged-in user (free ActiveRecord query, now works with association).
    @selected_client = Client.find_by(id: params[:client_id]) if params[:client_id]
    @employees = @selected_client ? @selected_client.employees : []  # Fetch employees for selected client (placeholder, expand in Step G).
  end
end