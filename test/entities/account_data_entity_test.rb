# frozen_string_literal: true

require 'test_helper'

class AccountDataEntityTest < ActiveSupport::TestCase
  test 'returns all accounts when no filters are applied' do
    entity = AccountDataEntity.new
    result = entity.data

    assert_equal Account.count, result.size
    assert_equal Account.pluck(:id).sort, result.pluck(:id).sort
  end

  test 'returns accounts for the specified users' do
    user = users(:one)
    expected_accounts = user.accounts
    assert_not_empty expected_accounts, 'User must have associted accounts for this test'

    entity = AccountDataEntity.new(user_ids: [user.id])
    result = entity.data

    assert_equal expected_accounts.pluck(:id).sort, result.pluck(:id).sort
  end

  test 'returns accounts of the specified types' do
    entity = AccountDataEntity.new(account_types: ['liabilities'])
    result = entity.data

    expected_accounts = Account.where(account_type: 'liabilities')

    assert_equal expected_accounts.size, result.size
    assert_equal expected_accounts.pluck(:id).sort, result.pluck(:id).sort
  end

  test 'returns accounts that match both filters' do
    user = users(:one)
    expected_accounts = Account.where(user_id: user.id).where(account_type: 'assets')
    assert_not_empty expected_accounts, 'Accounts with user and type are necessary for this test'

    entity = AccountDataEntity.new(user_ids: [user.id], account_types: ['assets'])
    result = entity.data

    assert_equal expected_accounts.pluck(:id).sort, result.pluck(:id).sort
  end
end
