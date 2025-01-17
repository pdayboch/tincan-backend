# frozen_string_literal: true

# == Schema Information
#
# Table name: plaid_items
#
#  id                     :bigint           not null, primary key
#  user_id                :bigint           not null
#  access_key             :string           not null
#  item_id                :string
#  institution_id         :string
#  sync_cursor            :string
#  transactions_synced_at :datetime
#  accounts_synced_at     :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
class PlaidItem < ApplicationRecord
  belongs_to :user

  before_destroy :remove_item_from_plaid

  def remove_item_from_plaid
    # TODO: Implement logic to remove item from Plaid, and block delete if failure.
  end
end
