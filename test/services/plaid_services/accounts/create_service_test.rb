# frozen_string_literal: true

require 'test_helper'

module PlaidServices
  module Accounts
    class CreateServiceTest < ActiveSupport::TestCase
      test 'correctly saves the new account' do
        item = plaid_items(:no_accounts)

        account_data = Plaid::AccountBase.new(
          account_id: 'new-account-id',
          name: 'new credit card',
          type: 'credit',
          subtype: 'credit card',
          balances: Plaid::AccountBalance.new(current: 53.55)
        )

        CreateService.new(item).call(account_data)

        new_account = item.reload.accounts.find_by(plaid_account_id: 'new-account-id')

        assert_not_nil new_account
        assert_equal item.user_id, new_account.user_id
        assert_equal item.id, new_account.plaid_item_id
        assert_equal 'new-account-id', new_account.plaid_account_id
        assert_equal 'new credit card', new_account.name
        assert_equal 'liabilities', new_account.account_type
        assert_equal 'credit cards', new_account.account_subtype
        assert_equal 53.55, new_account.current_balance
      end

      test 'returns the newly created account' do
        item = plaid_items(:no_accounts)

        account_data = Plaid::AccountBase.new(
          account_id: 'new-account-id',
          name: 'new credit card',
          type: 'credit',
          subtype: 'credit card',
          balances: Plaid::AccountBalance.new(current: 53.55)
        )

        new_account = CreateService.new(item).call(account_data)

        assert_not_nil new_account
        assert_equal item.user_id, new_account.user_id
        assert_equal item.id, new_account.plaid_item_id
        assert_equal 'new-account-id', new_account.plaid_account_id
        assert_equal 'new credit card', new_account.name
        assert_equal 'liabilities', new_account.account_type
        assert_equal 'credit cards', new_account.account_subtype
        assert_equal 53.55, new_account.current_balance
      end

      test 'correctly creates account with nil balance when balance is unavailable' do
        item = plaid_items(:no_accounts)

        account_data = Plaid::AccountBase.new(
          account_id: 'new-account-id',
          name: 'new credit card',
          type: 'credit',
          subtype: 'credit card'
        )

        CreateService.new(item).call(account_data)

        new_account = item.reload.accounts.find_by(plaid_account_id: 'new-account-id')

        assert_not_nil new_account
        assert_nil new_account.current_balance
      end

      test 'skips creation and logs error when duplicate account exists' do
        item = plaid_items(:with_multiple_accounts)
        existing_account = item.accounts.first
        account_data = Plaid::AccountBase.new(
          account_id: existing_account.plaid_account_id,
          name: 'account-name',
          type: 'credit',
          subtype: 'credit_card'
        )

        expected_msg = 'PlaidServices::Accounts::Create - ' \
                       'Attempted to create a Plaid account which already exists: ' \
                       "plaid_account_id: #{existing_account.plaid_account_id}"
        Rails.logger.expects(:error).with(expected_msg)
        CreateService.new(item).call(account_data)
      end

      test 'returns the existing account when duplicate account exists' do
        item = plaid_items(:with_multiple_accounts)
        existing_account = item.accounts.first
        account_data = Plaid::AccountBase.new(
          account_id: existing_account.plaid_account_id,
          name: 'account-name',
          type: 'credit',
          subtype: 'credit_card'
        )

        returned_account = CreateService.new(item).call(account_data)

        assert_equal existing_account.id, returned_account.id
      end

      test 'raises RecordNotFound when duplicate account exists on different item' do
        item = plaid_items(:with_multiple_accounts)
        item2 = plaid_items(:new_item)
        existing_account = item.accounts.first
        account_data = Plaid::AccountBase.new(
          account_id: existing_account.plaid_account_id,
          name: 'account-name',
          type: 'credit',
          subtype: 'credit_card'
        )

        assert_raises(ActiveRecord::RecordNotFound) do
          CreateService.new(item2).call(account_data)
        end
      end

      test 'raises InvalidAccountType error on account type' do
        item = plaid_items(:no_accounts)

        account_data = Plaid::AccountBase.new(
          account_id: 'new-account-id',
          name: 'new credit card',
          type: 'bad',
          subtype: 'bad subtype',
          balances: Plaid::AccountBalance.new(current: 53.55)
        )

        assert_raises(Plaid::AccountTypeMapper::InvalidAccountType) do
          CreateService.new(item).call(account_data)
        end
      end
    end
  end
end
