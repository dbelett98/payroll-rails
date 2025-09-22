class PayrollRunsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_payroll_run, only: [:show, :edit, :update, :destroy]
  before_action :set_client, only: [:index, :new, :create]

  # GET /payroll_runs
  def index
    @client = Client.find(params[:client_id]) if params[:client_id].present?
    
    # Base scope - user's payroll runs
    @payroll_runs = if @client
      @client.payroll_runs
    else
      PayrollRun.joins(:client).where(clients: { user: current_user })
    end
    
    # Apply filters
    @payroll_runs = apply_filters(@payroll_runs)
    
    # For statistics
    @clients = current_user.clients
    @selected_client = @client
    
    # Counts for dashboard
    @total_runs = @payroll_runs.count
    @pending_approval = @payroll_runs.where(status: ['draft', 'review']).count
    @processed_runs = @payroll_runs.where(status: 'processed').count
    
    respond_to do |format|
      format.html
      format.json {
        render json: {
          payroll_runs_html: render_to_string(
            partial: 'payroll_runs_table',
            locals: { payroll_runs: @payroll_runs }
          ),
          total_count: @total_runs,
          pending_count: @pending_approval
        }
      }
    end
  end

  # GET /payroll_runs/:id
  def show
    @client = @payroll_run.client
    @payroll_entries = @payroll_run.payroll_entries.includes(:employee)
  end

  # GET /payroll_runs/new
  def new
    puts "=== DEBUG: New action ==="
    puts "Client ID param: #{params[:client_id]}"
    puts "Client object: #{@client.inspect}"
    puts "Client employees count: #{@client&.employees&.count}"
    
    @payroll_run = @client.payroll_runs.build
    @payroll_run.run_date = Date.current
    @payroll_run.pay_frequency = 'biweekly'
    
    # Set default pay period
    start_date, end_date = PayrollRun.calculate_pay_period('biweekly', Date.current)
    @payroll_run.pay_period_start = start_date
    @payroll_run.pay_period_end = end_date
  end

  # POST /payroll_runs
  def create
    @payroll_run = @client.payroll_runs.build(payroll_run_params)
    @payroll_run.status_changed_by = current_user.email
    
    puts "=== DEBUG: PayrollRun Create ==="
    puts "Permitted params: #{payroll_run_params.inspect}"
    
    if @payroll_run.save
      puts "✅ SUCCESS: PayrollRun created successfully"
      redirect_to payroll_run_path(@payroll_run), notice: 'Payroll run created successfully.'
    else
      puts "❌ FAILED: Create errors: #{@payroll_run.errors.full_messages}"
      render :new, status: :unprocessable_entity
    end
  end

  # GET /payroll_runs/:id/edit
  def edit
    @client = @payroll_run.client
    
    unless @payroll_run.editable?
      redirect_to @payroll_run, alert: "Cannot edit payroll run in #{@payroll_run.status} status."
      return
    end
  end

  # PATCH/PUT /payroll_runs/:id
  def update
    @client = @payroll_run.client
    
    unless @payroll_run.editable?
      redirect_to @payroll_run, alert: "Cannot edit payroll run in #{@payroll_run.status} status."
      return
    end
    
    puts "=== DEBUG: PayrollRun Update ==="
    puts "PayrollRun ID: #{@payroll_run.id}"
    puts "Current status: #{@payroll_run.status}"
    puts "Permitted params: #{payroll_run_params.inspect}"
    
    if @payroll_run.update(payroll_run_params)
      puts "✅ SUCCESS: PayrollRun updated!"
      redirect_to @payroll_run, notice: 'Payroll run updated successfully.'
    else
      puts "❌ FAILED: Update errors: #{@payroll_run.errors.full_messages}"
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /payroll_runs/:id
  def destroy
    client = @payroll_run.client
    
    if @payroll_run.processed?
      redirect_to @payroll_run, alert: 'Cannot delete processed payroll runs. Use void instead.'
      return
    end
    
    @payroll_run.destroy
    redirect_to payroll_runs_path(client_id: client.id), notice: 'Payroll run deleted successfully.'
  end
  
  # ===== STATUS WORKFLOW ACTIONS =====
  
  # PATCH /payroll_runs/:id/submit_for_review
  def submit_for_review
    if @payroll_run.transition_to!('review', current_user)
      redirect_to @payroll_run, notice: 'Payroll run submitted for review.'
    else
      redirect_to @payroll_run, alert: 'Could not submit payroll run for review.'
    end
  end
  
  # PATCH /payroll_runs/:id/approve
  def approve
    if @payroll_run.transition_to!('approved', current_user)
      redirect_to @payroll_run, notice: 'Payroll run approved.'
    else
      redirect_to @payroll_run, alert: 'Could not approve payroll run.'
    end
  end
  
  # PATCH /payroll_runs/:id/process
  def mark_as_processed
    if @payroll_run.transition_to!('processed', current_user)
      # TODO: In Step O4, this will generate PayrollEntry records
      redirect_to @payroll_run, notice: 'Payroll run processed successfully.'
    else
      redirect_to @payroll_run, alert: 'Could not process payroll run.'
    end
  end
  
  # PATCH /payroll_runs/:id/void
  def void
    if @payroll_run.transition_to!('voided', current_user)
      redirect_to @payroll_run, notice: 'Payroll run voided.'
    else
      redirect_to @payroll_run, alert: 'Could not void payroll run.'
    end
  end
  
  # PATCH /payroll_runs/:id/return_to_draft
  def return_to_draft
    if @payroll_run.transition_to!('draft', current_user)
      redirect_to @payroll_run, notice: 'Payroll run returned to draft.'
    else
      redirect_to @payroll_run, alert: 'Could not return payroll run to draft.'
    end
  end

  private

  def set_payroll_run
    @payroll_run = PayrollRun.joins(:client).where(clients: { user: current_user }).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to payroll_runs_path, alert: 'Payroll run not found.'
  end
  
  def set_client
    client_id = params[:client_id] || params.dig(:payroll_run, :client_id)
    if client_id.present?
      @client = current_user.clients.find(client_id)
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to dashboard_path, alert: 'Client not found.'
  end

  def payroll_run_params
    params.require(:payroll_run).permit(
      :name, :description, :run_date, :pay_frequency, 
      :pay_period_start, :pay_period_end, :notes
    )
  end
  
  def apply_filters(scope)
    # Status filter
    if params[:status].present? && PayrollRun::STATUSES.include?(params[:status])
      scope = scope.where(status: params[:status])
    end
    
    # Pay frequency filter
    if params[:pay_frequency].present?
      scope = scope.where(pay_frequency: params[:pay_frequency])
    end
    
    # Date range filter
    if params[:start_date].present? && params[:end_date].present?
      begin
        start_date = Date.parse(params[:start_date])
        end_date = Date.parse(params[:end_date])
        scope = scope.where(run_date: start_date..end_date)
      rescue ArgumentError
        # Invalid date, ignore filter
      end
    end
    
    # Search filter (name, description)
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      scope = scope.where(
        "name ILIKE ? OR description ILIKE ?", 
        search_term, search_term
      )
    end
    
    scope.order(created_at: :desc)
  end
end