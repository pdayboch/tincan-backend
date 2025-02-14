class CreatePlaidItemAudits < ActiveRecord::Migration[7.2]
  def change
    create_table :plaid_item_audits do |t|
      t.bigint :user_id
      t.string :item_id
      t.string :institution_id
      t.text :billed_products, array: true, default: []
      t.text :products, array: true, default: []
      t.text :consented_data_scopes, array: true, default: []
      t.datetime :audit_created_at, null: false
      t.string :audit_op, null: false

      t.index :audit_created_at
      t.index :audit_op
      t.index :item_id
    end
  end
end
