class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.string :location, limit: 4
      t.datetime :time
      t.string :license_no, limit: 7

      t.timestamps null: false
    end
  end
end
