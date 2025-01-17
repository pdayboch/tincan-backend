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
require 'test_helper'

class PlaidItemTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
