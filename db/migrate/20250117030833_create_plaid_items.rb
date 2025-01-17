class CreatePlaidItems < ActiveRecord::Migration[7.2]
  def change
    create_table :plaid_items do |t|
      t.references :user, null: false, foreign_key: true
      t.string :access_key, null: false
      t.string :item_id, null: true
      t.string :institution_id, null: true
      t.string :sync_cursor, null: true
      t.datetime :transactions_synced_at, null: true
      t.datetime :accounts_synced_at, null: true

      t.timestamps
    end

    add_index :plaid_items, :item_id, unique: true
    add_index :plaid_items, :transactions_synced_at
    add_index :plaid_items, :accounts_synced_at
  end
end
