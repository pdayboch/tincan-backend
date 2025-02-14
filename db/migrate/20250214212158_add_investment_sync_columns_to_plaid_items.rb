class AddInvestmentSyncColumnsToPlaidItems < ActiveRecord::Migration[7.2]
  def change
    add_column :plaid_items, :investment_transactions_synced_at, :datetime
    add_column :plaid_items, :investment_transactions_sync_cursor, :string
  end
end
