# frozen_string_literal: true

require 'test_helper'

module PlaidServices
  module Transactions
    class SyncServiceTest < ActiveSupport::TestCase
      setup do
        @mock_api = mock('plaid-api')
        PlaidServices::Api.stubs(:new).returns(@mock_api)
      end

      test 'marks item transactions_synced_at after successful sync' do
        item = plaid_items(:new_item)

        @mock_api.expects(:transactions_sync)
                 .returns(
                   accounts: [],
                   added: [],
                   modified: [],
                   removed: [],
                   next_cursor: 'next-cursor-2'
                 )

        Timecop.freeze(Time.zone.local(2025, 1, 31, 12, 0, 0)) do
          SyncService.new(item).call

          assert_equal Time.zone.local(2025, 1, 31, 12, 0, 0),
                       item.transactions_synced_at
          assert 'next-cursor-2', item.reload.transaction_sync_cursor
        end
      end

      test 'raises Plaid::ApiRateLimitError when rate limit exceeded' do
        item = plaid_items(:new_item)

        rate_limit_error = Plaid::ApiError.new(
          data: { 'error_type' => Plaid::ApiRateLimitError::ERROR_TYPE }
        )
        @mock_api.expects(:transactions_sync)
                 .raises(rate_limit_error)

        assert_raises Plaid::ApiRateLimitError do
          SyncService.new(item).call
        end
      end

      test 'logs warning on Plaid::ApiError NO_ACCOUNTS error code' do
        item = plaid_items(:new_item)

        api_error = Plaid::ApiError.new(
          data: {
            'error_type' => 'ITEM_ERROR',
            'error_code' => 'NO_ACCOUNTS'
          }
        )
        @mock_api.expects(:transactions_sync)
                 .raises(api_error)

        msg = 'Transactions::Sync - no accounts available to sync ' \
              "transactions on PlaidItem: #{item.item_id}"
        Rails.logger.expects(:warn).with(msg)

        SyncService.new(item).call
      end

      test 'raises exception for non-rate limit errors' do
        item = plaid_items(:new_item)

        some_error = Plaid::ApiError.new(
          data: { 'error_type' => 'SERVER_ERROR' }
        )
        @mock_api.expects(:transactions_sync)
                 .raises(some_error)

        assert_raises Plaid::ApiError do
          SyncService.new(item).call
        end
      end
    end
  end
end
