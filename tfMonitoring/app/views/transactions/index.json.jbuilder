json.array!(@transactions) do |transaction|
  json.extract! transaction, :id, :location, :time, :license_no
  json.url transaction_url(transaction, format: :json)
end
