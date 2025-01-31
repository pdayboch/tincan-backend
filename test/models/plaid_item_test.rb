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
require 'test_helper'

class PlaidItemTest < ActiveSupport::TestCase
  test 'mark_accounts_as_synced updates the accounts_synced_at column' do
    item = plaid_items(:new_item)
    Timecop.freeze(Time.zone.local(2025, 1, 31, 12, 0, 0)) do
      item.mark_accounts_as_synced
      assert_equal Time.zone.local(2025, 1, 31, 12, 0, 0), item.accounts_synced_at
    end
  end

  test 'destroy removes item from plaid before deletion' do
    item = plaid_items(:new_item)
    item_remove_response = Plaid::ItemRemoveResponse.new(request_id: 'abcd')

    api = mock('plaid-api')
    PlaidServices::Api.stubs(:new).returns(api)
    api.expects(:destroy).returns(item_remove_response)

    assert_difference('PlaidItem.count', -1) do
      item.destroy
    end
  end

  test 'destroy allowed when plaid remove item fails due to item_not_found error' do
    item = plaid_items(:new_item)
    server_error = Plaid::ApiError.new(
      data: {
        'error_type' => 'ITEM_ERROR',
        'error_code' => PlaidItem::ITEM_NOT_FOUND_ERROR
      }
    )

    api = mock('plaid-api')
    PlaidServices::Api.stubs(:new).returns(api)
    api.expects(:destroy).raises(server_error)

    assert_difference('PlaidItem.count', -1) do
      item.destroy
    end
  end

  test 'destroy is blocked when plaid remove item fails' do
    item = plaid_items(:new_item)
    server_error = Plaid::ApiError.new(
      data: {
        'error_type' => 'SERVER_ERROR',
        'error_code' => 'SERVER_ERROR'
      }
    )

    api = mock('plaid-api')
    PlaidServices::Api.stubs(:new).returns(api)
    api.expects(:destroy).raises(server_error)

    assert_no_difference('PlaidItem.count') do
      assert_raises(Plaid::ApiError) do
        item.destroy
      end
    end
  end
end
