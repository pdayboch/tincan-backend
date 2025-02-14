# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_02_14_212158) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "category_type", ["income", "spend", "transfer"]

  create_table "accounts", force: :cascade do |t|
    t.string "name", null: false
    t.string "account_type"
    t.boolean "active", default: true
    t.boolean "deletable", default: true
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "statement_directory"
    t.string "parser_class"
    t.string "plaid_account_id"
    t.string "institution_name"
    t.string "account_subtype"
    t.decimal "current_balance", precision: 10, scale: 2
    t.bigint "plaid_item_id"
    t.index ["plaid_account_id"], name: "index_accounts_on_plaid_account_id", unique: true
    t.index ["plaid_item_id"], name: "index_accounts_on_plaid_item_id"
    t.index ["user_id"], name: "index_accounts_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.enum "category_type", enum_type: "category_type"
    t.index ["category_type"], name: "index_categories_on_category_type"
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "categorization_conditions", force: :cascade do |t|
    t.bigint "categorization_rule_id", null: false
    t.string "transaction_field", null: false
    t.string "match_type", null: false
    t.string "match_value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["categorization_rule_id"], name: "index_categorization_conditions_on_categorization_rule_id"
  end

  create_table "categorization_rules", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.bigint "subcategory_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_categorization_rules_on_category_id"
    t.index ["subcategory_id"], name: "index_categorization_rules_on_subcategory_id"
  end

  create_table "plaid_item_audits", force: :cascade do |t|
    t.bigint "user_id"
    t.string "item_id"
    t.string "institution_id"
    t.text "billed_products", default: [], array: true
    t.text "products", default: [], array: true
    t.text "consented_data_scopes", default: [], array: true
    t.datetime "audit_created_at", null: false
    t.string "audit_op", null: false
    t.index ["audit_created_at"], name: "index_plaid_item_audits_on_audit_created_at"
    t.index ["audit_op"], name: "index_plaid_item_audits_on_audit_op"
    t.index ["item_id"], name: "index_plaid_item_audits_on_item_id"
  end

  create_table "plaid_items", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "access_key", null: false
    t.string "item_id"
    t.string "institution_id"
    t.string "transaction_sync_cursor"
    t.datetime "transactions_synced_at"
    t.datetime "accounts_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "institution_name"
    t.text "billed_products", default: [], array: true
    t.text "products", default: [], array: true
    t.text "consented_data_scopes", default: [], array: true
    t.datetime "investment_transactions_synced_at"
    t.string "investment_transactions_sync_cursor"
    t.index ["accounts_synced_at"], name: "index_plaid_items_on_accounts_synced_at"
    t.index ["item_id"], name: "index_plaid_items_on_item_id", unique: true
    t.index ["transactions_synced_at"], name: "index_plaid_items_on_transactions_synced_at"
    t.index ["user_id"], name: "index_plaid_items_on_user_id"
  end

  create_table "statements", force: :cascade do |t|
    t.date "statement_date"
    t.bigint "account_id", null: false
    t.float "statement_balance"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "pdf_file_path"
    t.index ["account_id"], name: "index_statements_on_account_id"
  end

  create_table "subcategories", force: :cascade do |t|
    t.string "name"
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_subcategories_on_category_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.date "transaction_date", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.text "description"
    t.bigint "account_id", null: false
    t.bigint "statement_id"
    t.bigint "category_id", null: false
    t.bigint "subcategory_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "notes"
    t.text "statement_description"
    t.date "statement_transaction_date"
    t.bigint "split_from_id", comment: "References the parent transaction if this transaction is a split"
    t.boolean "has_splits", default: false, null: false, comment: "Indicates if this transaction has associated split transactions"
    t.string "merchant_name"
    t.boolean "pending", default: false
    t.string "plaid_transaction_id"
    t.index ["account_id"], name: "index_transactions_on_account_id"
    t.index ["category_id"], name: "index_transactions_on_category_id"
    t.index ["plaid_transaction_id"], name: "index_transactions_on_plaid_transaction_id", unique: true, where: "(plaid_transaction_id IS NOT NULL)"
    t.index ["split_from_id"], name: "index_transactions_on_split_from_id_not_null", where: "(split_from_id IS NOT NULL)"
    t.index ["statement_id"], name: "index_transactions_on_statement_id"
    t.index ["subcategory_id"], name: "index_transactions_on_subcategory_id"
    t.index ["transaction_date", "id"], name: "index_transactions_on_transaction_date_and_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "accounts", "plaid_items"
  add_foreign_key "accounts", "users"
  add_foreign_key "categorization_conditions", "categorization_rules"
  add_foreign_key "categorization_rules", "categories"
  add_foreign_key "categorization_rules", "subcategories"
  add_foreign_key "plaid_items", "users"
  add_foreign_key "statements", "accounts"
  add_foreign_key "subcategories", "categories"
  add_foreign_key "transactions", "accounts"
  add_foreign_key "transactions", "categories"
  add_foreign_key "transactions", "statements"
  add_foreign_key "transactions", "subcategories"
  add_foreign_key "transactions", "transactions", column: "split_from_id", on_delete: :nullify
end
