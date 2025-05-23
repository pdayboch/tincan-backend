# frozen_string_literal: true

# == Schema Information
#
# Table name: accounts
#
#  id                  :bigint           not null, primary key
#  name                :string           not null
#  account_type        :string
#  active              :boolean          default(TRUE)
#  deletable           :boolean          default(TRUE)
#  user_id             :bigint           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  statement_directory :text
#  parser_class        :string
#  plaid_account_id    :string
#  institution_name    :string
#  account_subtype     :string
#  current_balance     :decimal(10, 2)
#  plaid_item_id       :bigint
#
class AccountSerializer < ActiveModel::Serializer
  attributes :id, :name, :active, :deletable

  attribute :accountType do
    object.account_type
  end

  attribute :accountSubtype do
    object.account_subtype
  end

  attribute :currentBalance do
    object.current_balance
  end

  attribute :institutionName do
    object.institution_name
  end

  attribute :manualAccountProvider do
    object.parser_class
  end

  attribute :plaidAccountEnabled do
    object.plaid_account_id.present?
  end

  attribute :userId do
    object.user_id
  end
end
