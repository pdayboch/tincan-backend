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
#  billed_products         :text             default([]), is an Array
#  products                :text             default([]), is an Array
#  consented_data_scopes   :text             default([]), is an Array
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

  test 'mark_transactions_as_synced updates the transactions_synced_at column' do
    item = plaid_items(:new_item)
    Timecop.freeze(Time.zone.local(2025, 1, 31, 12, 0, 0)) do
      item.mark_transactions_as_synced
      assert_equal Time.zone.local(2025, 1, 31, 12, 0, 0), item.transactions_synced_at
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

  # AUDIT TESTS
  test 'creating item creates correct audit' do
    user = users(:one)

    Timecop.freeze do
      time_now = Time.current

      assert_difference 'Plaid::ItemAudit.count', 1 do
        PlaidItem.create!(
          user_id: user.id,
          item_id: 'item-id',
          institution_id: 'ins-123',
          access_key: 'access-key'
        )
      end

      audit = Plaid::ItemAudit.where(item_id: 'item-id')
                              .order(audit_created_at: :desc)
                              .first
      assert_equal time_now, audit.audit_created_at
      assert_equal user.id, audit.user_id
      assert_equal 'item-id', audit.item_id
      assert_equal 'ins-123', audit.institution_id
    end
  end

  test 'updating item creates correct audit' do
    item = plaid_items(:new_item)
    item.institution_id = 'ins-123'
    item.billed_products = ['transactions']

    assert_difference 'Plaid::ItemAudit.count', 1 do
      item.save!
    end

    audit = Plaid::ItemAudit.where(item_id: item.item_id)
                            .order(audit_created_at: :desc)
                            .first
    assert_equal 'ins-123', audit.institution_id
    assert_equal ['transactions'], audit.billed_products
    assert_equal item.item_id, audit.item_id
  end

  test 'updating item non-audited attributes does not create audit' do
    item = plaid_items(:new_item)

    assert_no_difference 'Plaid::ItemAudit.count' do
      item.mark_transactions_as_synced
    end
  end

  test 'destroying item creates correct audit' do
    item = plaid_items(:with_products)

    item_remove_response = Plaid::ItemRemoveResponse.new(request_id: 'abcd')
    api = mock('plaid-api')
    PlaidServices::Api.stubs(:new).returns(api)
    api.expects(:destroy).returns(item_remove_response)

    assert_difference 'Plaid::ItemAudit.count', 1 do
      item.destroy
    end

    audit = Plaid::ItemAudit.where(item_id: item.item_id)
                            .order(audit_created_at: :desc)
                            .first
    assert_equal item.item_id, audit.item_id
    assert_equal item.institution_id, audit.institution_id
    assert_equal item.billed_products, audit.billed_products
    assert_equal item.products, audit.products
    assert_equal item.consented_data_scopes, audit.consented_data_scopes
  end
end
