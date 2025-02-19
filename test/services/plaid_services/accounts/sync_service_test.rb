# frozen_string_literal: true

require 'test_helper'

module PlaidServices
  module Accounts
    class SyncServiceTest < ActiveSupport::TestCase
      setup do
        @mock_api = mock('plaid-api')
        PlaidServices::Api.stubs(:new).returns(@mock_api)
      end

      test 'raises argumentError when plaid_item is incorrect type' do
        expected_msg = 'plaid_item must be of type PlaidItem: String'
        error = assert_raises ArgumentError do
          SyncService.new('string')
        end

        assert_equal expected_msg, error.message
      end

      test 'correctly syncs item data' do
        item = plaid_items(:new_item)
        accounts_data = Plaid::AccountsGetResponse.new(
          item: Plaid::Item.new(item_id: item.item_id),
          accounts: []
        )

        @mock_api.expects(:accounts)
                 .at_least_once
                 .returns(accounts_data)

        mock_item_sync = mock('mock-item-sync')
        Item::SyncService.expects(:new)
                         .with(item)
                         .returns(mock_item_sync)
        mock_item_sync.expects(:call)
                      .with(accounts_data.item)
                      .returns(true)

        SyncService.new(item).call
      end

      test 'correctly creates new accounts' do
        item = plaid_items(:no_accounts)

        accounts_data = Plaid::AccountsGetResponse.new(
          item: Plaid::Item.new(item_id: item.item_id),
          accounts: [
            Plaid::AccountBase.new(
              account_id: 'new-account-id',
              name: 'new credit card',
              type: 'credit',
              subtype: 'credit card',
              balances: Plaid::AccountBalance.new(current: 53.55)
            ),
            Plaid::AccountBase.new(
              account_id: 'new-account2-id',
              name: 'new investment',
              type: 'investment',
              subtype: 'brokerage',
              balances: Plaid::AccountBalance.new(current: 1253.55)
            )
          ]
        )

        @mock_api.expects(:accounts)
                 .at_least_once
                 .returns(accounts_data)

        mock_item_sync = mock('mock-item-sync')
        Item::SyncService.expects(:new).returns(mock_item_sync)
        mock_item_sync.expects(:call).returns(true)

        SyncService.new(item).call

        new_account = item.reload.accounts.find_by(plaid_account_id: 'new-account-id')
        new_account2 = item.reload.accounts.find_by(plaid_account_id: 'new-account2-id')

        assert_not_nil new_account
        assert_equal item.user_id, new_account.user_id
        assert_equal item.id, new_account.plaid_item_id
        assert_equal 'new-account-id', new_account.plaid_account_id
        assert_equal 'new credit card', new_account.name
        assert_equal 'liabilities', new_account.account_type
        assert_equal 'credit cards', new_account.account_subtype
        assert_equal 53.55, new_account.current_balance

        assert_not_nil new_account2
        assert_equal item.user_id, new_account2.user_id
        assert_equal item.id, new_account2.plaid_item_id
        assert_equal 'new-account2-id', new_account2.plaid_account_id
        assert_equal 'new investment', new_account2.name
        assert_equal 'assets', new_account2.account_type
        assert_equal 'investments', new_account2.account_subtype
        assert_equal 1253.55, new_account2.current_balance
      end

      test 'account creation logs and skips invalid account types' do
        item = plaid_items(:no_accounts)

        accounts_data = Plaid::AccountsGetResponse.new(
          item: Plaid::Item.new(item_id: item.item_id),
          accounts: [
            Plaid::AccountBase.new(
              account_id: 'new-account-id',
              name: 'new credit card',
              type: 'bad',
              subtype: 'bad subtype',
              balances: Plaid::AccountBalance.new(current: 53.55)
            ),
            Plaid::AccountBase.new(
              account_id: 'new-account-id',
              name: 'new investment',
              type: 'depository',
              subtype: 'checking',
              balances: Plaid::AccountBalance.new(current: 1253.55)
            )
          ]
        )

        @mock_api.expects(:accounts)
                 .at_least_once
                 .returns(accounts_data)

        mock_item_sync = mock('mock-item-sync')
        Item::SyncService.expects(:new).returns(mock_item_sync)
        mock_item_sync.expects(:call).returns(true)

        Rails.logger.expects(:error).with('Unknown Plaid account type: bad. Skipping account creation.')

        SyncService.new(item).call

        bad_account = item.reload.accounts.find_by(plaid_account_id: 'bad-account-id')
        new_account = item.reload.accounts.find_by(plaid_account_id: 'new-account-id')

        assert_nil bad_account

        assert_not_nil new_account
        assert_equal item.user_id, new_account.user_id
        assert_equal item.id, new_account.plaid_item_id
        assert_equal 'new-account-id', new_account.plaid_account_id
        assert_equal 'new investment', new_account.name
        assert_equal 'assets', new_account.account_type
        assert_equal 'cash', new_account.account_subtype
        assert_equal 1253.55, new_account.current_balance
      end

      test 'correctly updates existing accounts' do
        item = plaid_items(:with_multiple_accounts)
        account = item.accounts.first
        new_balance = account.current_balance + 2.00
        new_name = 'a new account name'

        accounts_data = Plaid::AccountsGetResponse.new(
          item: Plaid::Item.new(item_id: item.item_id),
          accounts: [
            Plaid::AccountBase.new(
              account_id: account.plaid_account_id,
              name: new_name,
              type: account.account_type,
              subtype: account.account_subtype,
              balances: Plaid::AccountBalance.new(current: new_balance)
            )
          ]
        )

        @mock_api.expects(:accounts)
                 .at_least_once
                 .returns(accounts_data)

        mock_item_sync = mock('mock-item-sync')
        Item::SyncService.expects(:new).returns(mock_item_sync)
        mock_item_sync.expects(:call).returns(true)

        SyncService.new(item).call

        assert_equal new_balance, account.reload.current_balance
        assert_equal new_name, account.name
      end

      test 'marks item accounts_synced_at after successful sync' do
        item = plaid_items(:new_item)

        accounts_data = Plaid::AccountsGetResponse.new(
          item: Plaid::Item.new(item_id: item.item_id),
          accounts: []
        )

        @mock_api.expects(:accounts)
                 .at_least_once
                 .returns(accounts_data)

        mock_item_sync = mock('mock-item-sync')
        Item::SyncService.expects(:new).returns(mock_item_sync)
        mock_item_sync.expects(:call).returns(true)

        Timecop.freeze(Time.zone.local(2025, 1, 31, 12, 0, 0)) do
          SyncService.new(item).call
          assert_equal Time.zone.local(2025, 1, 31, 12, 0, 0), item.accounts_synced_at
        end
      end

      test 'deactivates missing accounts from latest fetch' do
        item = plaid_items(:with_multiple_accounts)
        account_to_deactivate = item.accounts.first
        assert account_to_deactivate.active, 'account to deactivate must start as active'

        remaining_accounts = item.accounts.reject { |a| a.id == account_to_deactivate.id }

        accounts_data = Plaid::AccountsGetResponse.new(
          item: Plaid::Item.new(item_id: item.item_id),
          accounts: remaining_accounts.map do |a|
            Plaid::AccountBase.new(account_id: a.plaid_account_id,
                                   name: a.name,
                                   balances: Plaid::AccountBalance.new(current: a.current_balance))
          end
        )

        @mock_api.expects(:accounts)
                 .at_least_once
                 .returns(accounts_data)

        mock_item_sync = mock('mock-item-sync')
        Item::SyncService.expects(:new).returns(mock_item_sync)
        mock_item_sync.expects(:call).returns(true)

        SyncService.new(item).call
        assert_not account_to_deactivate.reload.active
      end

      test 'raises PlaidApiRateLimitError when API rate limit exceeded' do
        item = plaid_items(:no_accounts)

        rate_limit_error = Plaid::ApiError.new(
          data: { 'error_type' => SyncService::RATE_LIMIT_EXCEEDED }
        )

        @mock_api.expects(:accounts)
                 .raises(rate_limit_error)

        assert_raises(SyncService::PlaidApiRateLimitError) do
          SyncService.new(item).call
        end
      end

      test 'raises exception for non-rate limit errors' do
        item = plaid_items(:no_accounts)

        some_error = Plaid::ApiError.new(
          data: { 'error_type' => 'SERVER_ERROR' }
        )

        @mock_api.expects(:accounts)
                 .raises(some_error)

        assert_raises Plaid::ApiError do
          SyncService.new(item).call
        end
      end
    end
  end
end
