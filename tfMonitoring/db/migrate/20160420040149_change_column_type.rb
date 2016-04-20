class ChangeColumnType < ActiveRecord::Migration
  def change
    change_column :transactions, :time, :string
  end
end
