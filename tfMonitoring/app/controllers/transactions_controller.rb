class TransactionsController < ApplicationController
  before_action :set_transaction, only: [:show, :edit, :update, :destroy]
  before_action :ensure_json_format, only: :set_vehicle_data

  #Accept JSON request
  protect_from_forgery with: :null_session, only: Proc.new { |c| c.request.format.json? }

  require 'rest-client'

  #POST /transactions/set_vehicle_data.json
  def set_vehicle_data

    @existingRecord=Transaction.where('license_no = ?', params[:license_no]).first

    if !(@existingRecord.blank?)

      @sendText = @existingRecord.location.to_s+'-'+params[:location]+'|'+params[:license_no]+'|'+@existingRecord.time.to_s

      # Send POST request to Flume on Hadoop Master
      RestClient.post 'http://192.168.1.11:5140',{'route' => @existingRecord.location.to_s+'-'+params[:location], 'license_no' => @existingRecord.license_no.to_s, 'time' => @existingRecord.time.to_s}.to_json, :content_type => :json

      @existingRecord.delete

      render :text => 'Data was sent'
    else
      @transaction = Transaction.new(transaction_params)
      @transaction.location = params[:location]
      @transaction.license_no = params[:license_no]
      @transaction.time = params[:time]
      if @transaction.save
        render :text => 'buffering'
      else
        render :status => :unprocessable_entity
      end
    end

  end

  def ensure_json_format

    if request.content_type != 'application/json'
      render :text => 'Wrong FORMAT-Only JSON is acceptable', :status => 406
    end

  end

  # GET /transactions
  # GET /transactions.json
  def index
    @transactions = Transaction.all
  end

  # GET /transactions/1
  # GET /transactions/1.json
  def show
  end

  # GET /transactions/new
  def new
    @transaction = Transaction.new
  end

  # GET /transactions/1/edit
  def edit
  end

  # POST /transactions
  # POST /transactions.json
  def create
    @transaction = Transaction.new(transaction_params)

    respond_to do |format|
      if @transaction.save
        format.html { redirect_to @transaction, notice: 'Transaction was successfully created.' }
        format.json { render :show, status: :created, location: @transaction }
      else
        format.html { render :new }
        format.json { render json: @transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /transactions/1
  # PATCH/PUT /transactions/1.json
  def update
    respond_to do |format|
      if @transaction.update(transaction_params)
        format.html { redirect_to @transaction, notice: 'Transaction was successfully updated.' }
        format.json { render :show, status: :ok, location: @transaction }
      else
        format.html { render :edit }
        format.json { render json: @transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /transactions/1
  # DELETE /transactions/1.json
  def destroy
    @transaction.destroy
    respond_to do |format|
      format.html { redirect_to transactions_url, notice: 'Transaction was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_transaction
      @transaction = Transaction.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def transaction_params
      params.require(:transaction).permit(:location, :time, :license_no)
    end
end
