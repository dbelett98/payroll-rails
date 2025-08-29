# app/controllers/dashboards_controller.rb: Enhanced with AJAX filtering support
class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def show
    @clients = current_user.clients
    puts "Current User Clients: #{@clients.inspect}"  # Debug: Print clients to console (free Ruby method).
    @selected_client = Client.find_by(id: params[:client_id]) if params[:client_id].present?
    # Default to first client if no selection and clients exist
    @selected_client ||= @clients.first
    
    # Get base employees for selected client
    @employees = @selected_client ? @selected_client.employees : Employee.none
    puts "Selected Client: #{@selected_client.inspect}"  # Debug: Print selected client.
    puts "Base Employees Count: #{@employees.count}"  # Debug: Print employee count.
    
    # Apply filters if present
    if params[:search].present? || params[:status].present?
      @employees = apply_filters(@employees, params[:search], params[:status])
      puts "Filtered Employees Count: #{@employees.count}"  # Debug: Print filtered count.
      puts "Search term: '#{params[:search]}', Status: '#{params[:status]}'"  # Debug: Print filter params.
    end
    
    @new_employee = Employee.new  # Initialize new employee for form (free).
    
    # Store filter state for view
    @current_search = params[:search]
    @current_status = params[:status]
    @has_filters = params[:search].present? || params[:status].present?

    # Handle AJAX requests for employee filtering
    respond_to do |format|
      format.html # Normal page load
      format.json {
        # Return JSON with employee data and filter state
        render json: {
          employees_html: render_to_string(
            partial: 'employees_table', 
            locals: { 
              employees: @employees, 
              selected_client: @selected_client 
            }
          ),
          filter_bar_html: render_to_string(
            partial: 'employee_filter_bar',
            locals: {
              selected_client: @selected_client,
              current_search: @current_search,
              current_status: @current_status,
              has_filters: @has_filters,
              employees: @employees
            }
          ),
          employee_count: @employees.count,
          total_count: @selected_client&.employees&.count || 0,
          has_filters: @has_filters
        }
      }
    end
  end

  private

  def apply_filters(employees, search_term, status_filter)
    filtered = employees
    
    # Apply search filter (searches name and title)
    if search_term.present?
      search_term = search_term.strip
      puts "🔍 Applying search filter: '#{search_term}'"
      filtered = filtered.where(
        "name ILIKE ? OR title ILIKE ?", 
        "%#{search_term}%", 
        "%#{search_term}%"
      )
    end
    
    # Apply status filter
    if status_filter.present?
      puts "📊 Applying status filter: '#{status_filter}'"
      filtered = filtered.where(status: status_filter)
    end
    
    filtered
  end
end