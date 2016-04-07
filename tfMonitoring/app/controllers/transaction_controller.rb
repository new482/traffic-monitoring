class TransactionController < ApplicationController

	before_action :ensure_json_format, only: :set_vehicle_data
	skip_before_action :verify_authenticity_token
	#skip_before_action :ensure_json_format, only: :get_vehicle_data
	

	#GET /transactions/get_vehicle_data.json
	def get_vehicle_data
		#@transactions = Transaction.all
		#render json: @transactions
	end

	#POST /transactions/set_vehicle_data.json
	def set_vehicle_data

		render :status => 200, :text => 'JSON was received', :content_type => 'text/html'

		#respond_to do |format|
		#	format.json{ render :status => 200 }
		#end

=begin
		@transaction = Transaction.new
		@transaction.location = params[:location]
		@transaction.time = params[:time]
		@transaction.license_no = params[:license_no]
		

		respond_to do |format|
			if @transaction.save
				format.json{ render json: @transaction, status: :created }
			else
				format.json{ render json: @transaction.errors, status: :unprocessable_entity }
			end
		end
=end
	end

	#DELETE /transactions/remove_all_data
	def remove_all_data
		#@transactions = Transaction.all
		
		#if @transactions.destroy_all
		#	render json: @transactions
		#end
	end

	def ensure_json_format
		#return if request.format != :json
		#	render	:nothing => true, :status => 406
		if request.content_type != 'application/json'
			render :text => 'Wrong FORMAT-Only JSON is acceptable', :status => 406
		end
		#render :nothing => true, :status => 406 unless params[:format] == 'json' || request.headers["Accept"] =~ /json/
	end

	#private
	#	def transaction_params
	#		params.require(:transaction).permit(:location, :time, :license_no)
	#	end
end
