class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.string :location
      t.datetime :time
      t.string :license_no

      t.timestamps null: false
    end
  end
end
