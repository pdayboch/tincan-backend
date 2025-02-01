class AddPlaidTransactionIdIndexToTransactions < ActiveRecord::Migration[7.2]
  def change
    add_index :transactions, :plaid_transaction_id,
      unique: true,
      where: "plaid_transaction_id IS NOT NULL"
  end
end
