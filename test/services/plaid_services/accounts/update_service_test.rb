# frozen_string_literal: true

require 'test_helper'

module PlaidServices
  module Accounts
    class UpdateServiceTest < ActiveSupport::TestCase
      test 'correctly updates account' do
        item = plaid_items(:with_multiple_accounts)
        account = item.accounts.first
        new_balance = account.current_balance + 2.00
        new_name = 'a new account name'

        account_data = Plaid::AccountBase.new(
          account_id: account.plaid_account_id,
          name: new_name,
          type: account.account_type,
          subtype: account.account_subtype,
          balances: Plaid::AccountBalance.new(current: new_balance)
        )

        UpdateService.new(item, account).call(account_data)

        assert_equal new_balance, account.reload.current_balance
        assert_equal new_name, account.name
      end

      test 'copies item institution_name if set' do
        item = plaid_items(:with_multiple_accounts)
        item.update(institution_name: 'a new bank')
        account = item.accounts.first

        account_data = Plaid::AccountBase.new(
          account_id: account.plaid_account_id,
          name: account.name,
          type: account.account_type,
          subtype: account.account_subtype,
          balances: Plaid::AccountBalance.new(current: account.current_balance)
        )

        UpdateService.new(item, account).call(account_data)

        assert_equal 'a new bank', account.reload.institution_name
      end

      test 'does not copy item institution_name if nil' do
        item = plaid_items(:with_multiple_accounts)
        item.update(institution_name: nil)
        account = item.accounts.first
        account.update(institution_name: 'some bank')

        account_data = Plaid::AccountBase.new(
          account_id: account.plaid_account_id,
          name: account.name,
          type: account.account_type,
          subtype: account.account_subtype,
          balances: Plaid::AccountBalance.new(current: account.current_balance)
        )

        UpdateService.new(item, account).call(account_data)

        assert_equal 'some bank', account.reload.institution_name
      end
    end
  end
end
