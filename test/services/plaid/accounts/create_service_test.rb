# frozen_string_literal: true

require 'test_helper'

module Plaid
  module Accounts
    class CreateServiceTest < ActiveSupport::TestCase
      test 'correctly creates new account' do
        item = plaid_items(:no_accounts)

        account_data = Plaid::AccountBase.new(
          account_id: 'new-account-id',
          name: 'new credit card',
          type: 'credit',
          subtype: 'credit card',
          balances: Plaid::AccountBalance.new(current: 53.55)
        )

        Plaid::Accounts::CreateService.new(item).call(account_data)

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

      test 'raises InvalidAccountType error on account type' do
        item = plaid_items(:no_accounts)

        account_data = Plaid::AccountBase.new(
          account_id: 'new-account-id',
          name: 'new credit card',
          type: 'bad',
          subtype: 'bad subtype',
          balances: Plaid::AccountBalance.new(current: 53.55)
        )

        assert_raises(AccountTypeMapper::InvalidAccountType) do
          Plaid::Accounts::CreateService.new(item).call(account_data)
        end
      end
    end
  end
end
