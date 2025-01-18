class AddTransactionTablePlaidColumns < ActiveRecord::Migration[7.2]
  def change
    change_table :transactions do |t|
      t.string  :merchant_name, null: true
      t.boolean :pending, default: false
      t.string :plaid_transaction_id, null: true
    end
  end
end
