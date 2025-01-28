class AddAndUpdatePlaidItemColumns < ActiveRecord::Migration[7.2]
  def change
    rename_column :plaid_items, :sync_cursor, :transaction_sync_cursor

    add_column :plaid_items, :institution_name, :string
  end
end
