# frozen_string_literal: true

require 'test_helper'

class AccountDataEntityTest < ActiveSupport::TestCase
  setup do
    @user1 = users(:one)
    @user2 = users(:two)
    @account1 = accounts(:one)
    @account2 = accounts(:two)
    @account3 = accounts(:three)
    @non_deletable_account = accounts(:non_deletable_account)
    @inactive_account = accounts(:inactive_account)
  end

  test 'returns all accounts when no filters are applied' do
    entity = AccountDataEntity.new
    result = entity.data

    assert_equal Account.count, result.size
    assert_includes result.pluck(:id), @account1.id
    assert_includes result.pluck(:id), @account2.id
    assert_includes result.pluck(:id), @account3.id
    assert_includes result.pluck(:id), @non_deletable_account.id
    assert_includes result.pluck(:id), @inactive_account.id
  end

  test 'returns accounts for the specified users' do
    entity = AccountDataEntity.new(user_ids: [@user1.id])
    result = entity.data

    assert_equal @user1.accounts.count, result.size
    assert_includes result.pluck(:id), @account1.id
    assert_includes result.pluck(:id), @account3.id
    assert_includes result.pluck(:id), @non_deletable_account.id
  end

  test 'returns accounts of the specified types' do
    entity = AccountDataEntity.new(account_types: ['credit card'])
    result = entity.data

    assert_equal 4, result.size
    assert_includes result.pluck(:id), @account1.id
    assert_includes result.pluck(:id), @account2.id
    assert_includes result.pluck(:id), @account3.id
    assert_includes result.pluck(:id), @inactive_account.id
  end

  test 'returns accounts that match both filters' do
    entity = AccountDataEntity.new(user_ids: [@user1.id], account_types: ['credit card'])
    result = entity.data

    assert_equal 3, result.size
    assert_includes result.pluck(:id), @account1.id
    assert_includes result.pluck(:id), @account3.id
    assert_includes result.pluck(:id), @inactive_account.id
  end
end
