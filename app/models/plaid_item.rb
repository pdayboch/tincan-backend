# frozen_string_literal: true

# == Schema Information
#
# Table name: plaid_items
#
#  id                      :bigint           not null, primary key
#  user_id                 :bigint           not null
#  access_key              :string           not null
#  item_id                 :string
#  institution_id          :string
#  transaction_sync_cursor :string
#  transactions_synced_at  :datetime
#  accounts_synced_at      :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  institution_name        :string
#
class PlaidItem < ApplicationRecord
  belongs_to :user
  has_many :accounts, dependent: :nullify

  before_destroy :remove_item_from_plaid

  ITEM_NOT_FOUND_ERROR = 'ITEM_NOT_FOUND'

  def mark_accounts_as_synced
    update(accounts_synced_at: Time.zone.now)
  end

  def mark_transactions_as_synced
    update(transactions_synced_at: Time.zone.now)
  end

  def remove_item_from_plaid
    PlaidServices::Api.new(access_key).destroy
  rescue Plaid::ApiError => e
    return true if e.data['error_code'] == ITEM_NOT_FOUND_ERROR

    raise e
  end
end
