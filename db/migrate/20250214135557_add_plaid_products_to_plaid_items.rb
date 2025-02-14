class AddPlaidProductsToPlaidItems < ActiveRecord::Migration[7.2]
  def change
    add_column :plaid_items, :billed_products, :text, array: true, default: []
    add_column :plaid_items, :products, :text, array: true, default: []
    add_column :plaid_items, :consented_data_scopes, :text, array: true, default: []
  end
end
