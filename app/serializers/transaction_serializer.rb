# frozen_string_literal: true

# == Schema Information
#
# Table name: transactions
#
#  id                         :bigint           not null, primary key
#  transaction_date           :date             not null
#  amount                     :decimal(10, 2)   not null
#  description                :text
#  account_id                 :bigint           not null
#  statement_id               :bigint
#  category_id                :bigint           not null
#  subcategory_id             :bigint           not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  notes                      :text
#  statement_description      :text
#  statement_transaction_date :date
#  split_from_id              :bigint
#  has_splits                 :boolean          default(FALSE), not null
#  merchant_name              :string
#  pending                    :boolean          default(FALSE)
#  plaid_transaction_id       :string
#
class TransactionSerializer < ActiveModel::Serializer
  attributes :id, :amount, :description, :notes, :pending

  attribute :accountId do
    object.account_id
  end

  attribute :transactionDate do
    object.transaction_date
  end

  attribute :statementTransactionDate do
    object.statement_transaction_date
  end

  attribute :statementDescription do
    object.statement_description
  end

  attribute :splitFromId do
    object.split_from_id
  end

  attribute :hasSplits do
    object.has_splits
  end

  attribute :userId do
    object.account.user_id
  end

  attribute :category do
    {
      id: object.category.id,
      name: object.category.name
    }
  end

  attribute :subcategory do
    {
      id: object.subcategory.id,
      name: object.subcategory.name
    }
  end
end
