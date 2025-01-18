class UpdateAccountsTableColumns < ActiveRecord::Migration[7.2]
  def change
    change_table :accounts do |t|
      t.remove :bank_name, type: :string

      t.string :plaid_account_id, null: true
      t.string :institution_name
      t.string :account_subtype, null: true
      t.decimal :current_balance, precision: 10, scale: 2
      t.references :plaid_item, foreign_key: true, null: true
    end

    add_index :accounts, :plaid_account_id, unique: true
  end
end
