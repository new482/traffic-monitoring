class TransactionsController < ApplicationController
  before_action :set_transaction, only: [:show, :edit, :update, :destroy]
  before_action :ensure_json_format, only: :set_vehicle_data

  #Accept JSON request
  protect_from_forgery with: :null_session, only: Proc.new { |c| c.request.format.json? }

  require 'rest-client'
  require 'hbase_thrift_ruby'
  require 'csv'

  $hbaseClient = ''
  $sumOfRoute = ''
  $arrayOfEndPoint = ''
  $transport = ''

  #POST /transactions/set_vehicle_data.json
  def set_vehicle_data
    @existingRecord=Transaction.where('license_no = ?', params[:license_no]).first

    if !(@existingRecord.blank?)

      # Send POST request to Flume on Hadoop Master
      route = @existingRecord.location.to_s+'-'+params[:location]
      license_no = params[:license_no]
      time = @existingRecord.time.to_s
      var = route+'|'+license_no+'|'+time
      RestClient.post('http://localhost:5140', [{:headers => {:host => 'web'}, :body => var}].to_json)
	    render :text => 'Data was sent to the Hadoop cluster.'
      @existingRecord.delete
      # end Send

    else
      @transaction = Transaction.new(transaction_params)
      @transaction.location = params[:location]
      @transaction.license_no = params[:license_no]
      @transaction.time = params[:time]
      if @transaction.save
        render :text => 'Data was buffered.'
      else
        render :status => :unprocessable_entity
      end
    end
  end

  def ensure_json_format
    if request.content_type != 'application/json'
      render :text => 'Wrong FORMAT!! Only JSON is accepted', :status => 406
    end
  end


  def generateOD
    $sumOfRoute.clear
    $arrayOfEndPoint.clear

    $transport.open

    temp1 = params[:rangeFrom].split('/')
    temp2 = params[:rangeTo].split('/')

    dateFrom = temp1[2].to_s+'-'+temp1[0].to_s+'-'+temp1[1].to_s
    dateTo = temp2[2].to_s+'-'+temp2[0].to_s+'-'+temp2[1].to_s

    # Return all the route in the request range from Hbase
    getRange = $hbaseClient.get("hbase_hive", ["*"],
                                "SingleColumnValueFilter('cf', 'time', "'>='", 'binary:#{dateFrom}') AND "+
                                    "SingleColumnValueFilter('cf', 'time', "'<='", 'binary:#{dateTo}')", {})

    $sumOfRoute = doSumHash(getRange) # Initiate Hash table to print in the dynamic OD table
    $arrayOfEndPoint = doArrayEndPoint(getRange) # Initiate number of end-points in the dynamic OD table

    respond_to do |format|
      format.html {redirect_to @transaction}
      format.js #render transaction/generateOD.js.erb
    end

    $transport.close
  end

  # Do Group by and Count for each entrypoint from Hbase
  def doSumHash(range)
    sumValue = Hash.new

    for i in 0..range.size-1
      if sumValue[range[i][1]].nil?
        sumValue[range[i][1]] = range[i][0].to_i
      else
        sumValue[range[i][1]] = sumValue[range[i][1]].to_i + range[i][0].to_i
      end
    end

    return sumValue
    sumValue.clear
  end

  # Generate the header of the OD table
  def doArrayEndPoint(range)
    arrayEndPoint = Array.new

    for i in 0..range.size-1
      var1 = range[i][1].split('-')[0]
      var2 = range[i][1].split('-')[1]

      if arrayEndPoint.index(var1).nil?
        arrayEndPoint << var1
      end

      if arrayEndPoint.index(var2).nil?
        arrayEndPoint << var2
      end
    end

    return arrayEndPoint
    arrayEndPoint.clear
  end

  # Generate the OD CSV file
  def getCSV
    tarray = Array.new

    csv_data = CSV.generate do |csv|
      tarray << 'OD Matrix'
      for i in 0..$arrayOfEndPoint.size-1
        tarray << $arrayOfEndPoint[i]
      end

      csv << tarray
      tarray.clear

      for i in 0..$arrayOfEndPoint.size-1
        tarray << $arrayOfEndPoint[i]
        for j in 0..$arrayOfEndPoint.size-1
          tarray << $sumOfRoute[$arrayOfEndPoint[i]+"-"+$arrayOfEndPoint[j]]
        end
        csv << tarray
        tarray.clear
      end
    end

    send_data csv_data, :type => 'text/csv; charset=iso-8859-1; header=present',
              :disposition => 'attachment; filename=OD_matrix.csv'
  end


  # GET /transactions
  # GET /transactions.json
  def index
    host = '192.168.1.11'
    port = 9090

    socket = Thrift::Socket.new(host, port)
    $transport = Thrift::BufferedTransport.new(socket)
    $transport.open
    protocol = Thrift::BinaryProtocol.new($transport)

    $hbaseClient = HBase::Client.new(protocol)
    $transport.close
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
