# frozen_string_literal: true

require 'test_helper'

module PlaidServices
  class SyncAccountsTest < ActiveSupport::TestCase
    test 'raises argumentError when plaid_item is incorrect type' do
      account_get_resp = Plaid::AccountsGetResponse.new
      expected_msg = 'plaid_item must be of type PlaidItem: String'
      error = assert_raises ArgumentError do
        PlaidServices::SyncAccounts.new('string', account_get_resp)
      end

      assert_equal expected_msg, error.message
    end

    test 'raises argumentError when accounts_data is incorrect type' do
      plaid_item = plaid_items(:new_item)
      expected_msg = 'accounts_data must be of type Plaid::AccountsGetResponse: String'
      error = assert_raises ArgumentError do
        PlaidServices::SyncAccounts.new(plaid_item, 'string')
      end

      assert_equal expected_msg, error.message
    end

    test 'raises DataConsistencyError when item_id does not match fetched data item_id' do
      item = plaid_items(:new_item)
      accounts_data = Plaid::AccountsGetResponse.new(
        item: Plaid::Item.new(item_id: 'wrong-item-id')
      )

      assert_raises SyncAccounts::DataConsistencyError do
        PlaidServices::SyncAccounts.new(item, accounts_data)
      end
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
          )
        ]
      )

      PlaidServices::SyncAccounts.new(item, accounts_data).call

      new_account = item.reload.accounts.first

      assert_not_nil new_account
      assert_equal item.user_id, new_account.user_id
      assert_equal item.id, new_account.plaid_item_id
      assert_equal 'new-account-id', new_account.plaid_account_id
      assert_equal 'new credit card', new_account.name
      assert_equal 'credit', new_account.account_type
      assert_equal 'credit card', new_account.account_subtype
      assert_equal 53.55, new_account.current_balance
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

      PlaidServices::SyncAccounts.new(item, accounts_data).call

      assert_equal new_balance, account.reload.current_balance
      assert_equal new_name, account.name
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

      PlaidServices::SyncAccounts.new(item, accounts_data).call
      assert_not account_to_deactivate.reload.active
    end
  end
end
