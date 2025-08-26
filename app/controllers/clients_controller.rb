# app/controllers/clients_controller.rb: Handles client CRUD (free open-source Rails controller).
class ClientsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_client, only: [:show, :edit, :update, :destroy]

  # GET /clients
  def index
    @clients = current_user.clients.includes(:employees)
  end

  # GET /clients/:id
  def show
    @employees = @client.employees
  end

  # GET /clients/new
  def new
    @client = current_user.clients.build
  end

  # POST /clients
  def create
    @client = current_user.clients.build(client_params)
    
    respond_to do |format|
      if @client.save
        format.html { redirect_to dashboard_path(client_id: @client.id), notice: 'Client created successfully.' }
        format.json { render json: @client, status: :created }
      else
        format.html { redirect_to dashboard_path, alert: "Error: #{@client.errors.full_messages.join(', ')}" }
        format.json { render json: @client.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /clients/:id/edit
  def edit
  end

  # PATCH/PUT /clients/:id
  def update
    respond_to do |format|
      if @client.update(client_params)
        format.html { redirect_to dashboard_path(client_id: @client.id), notice: 'Client updated successfully.' }
        format.json { render json: @client, status: :ok }
      else
        format.html { redirect_to dashboard_path(client_id: @client.id), alert: "Error: #{@client.errors.full_messages.join(', ')}" }
        format.json { render json: @client.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /clients/:id
  def destroy
    @client.destroy
    
    respond_to do |format|
      format.html { redirect_to dashboard_path, notice: 'Client deleted successfully.' }
      format.json { head :no_content }
    end
  end

  private

  def set_client
    @client = current_user.clients.find(params[:id])
  end

  def client_params
    params.require(:client).permit(:name, :bank_account, :ein, :address, :phone, :email)
  end
end