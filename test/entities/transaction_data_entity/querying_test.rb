# frozen_string_literal: true

require 'test_helper'

class TransactionDataEntityQueryingTest < ActiveSupport::TestCase
  test 'data returns the correct structure' do
    data = TransactionDataEntity.new.data
    assert data.key?(:meta)
    assert data[:meta].key?(:totalCount)
    assert data[:meta].key?(:filteredCount)
    assert data[:meta].key?(:prevPage)
    assert data[:meta].key?(:nextPage)
    assert data.key?(:transactions)
    assert data[:transactions].is_a?(Array)
  end

  test 'data returns transactions sorted by default (transaction_date desc)' do
    entity = TransactionDataEntity.new
    data = entity.data

    assert(data[:transactions].each_cons(2).all? { |a, b| a[:transactionDate] >= b[:transactionDate] })
  end

  test 'data returns transactions sorted by transaction_date asc' do
    entity = TransactionDataEntity.new(sort_direction: 'asc')
    data = entity.data

    assert(data[:transactions].each_cons(2).all? { |a, b| a[:transactionDate] <= b[:transactionDate] })
  end

  test 'data returns transactions sorted by amount asc' do
    entity = TransactionDataEntity.new(
      sort_by: 'amount',
      sort_direction: 'asc'
    )
    data = entity.data

    assert(data[:transactions].each_cons(2).all? { |a, b| a[:amount] <= b[:amount] })
  end

  test 'data returns transactions sorted by amount desc' do
    entity = TransactionDataEntity.new(
      sort_by: 'amount',
      sort_direction: 'desc'
    )
    data = entity.data

    assert(data[:transactions].each_cons(2).all? { |a, b| a[:amount] >= b[:amount] })
  end

  test 'data returns filtered transactions by accounts' do
    included_ids = [accounts(:one).id, accounts(:two).id]
    ignored_ids = [accounts(:three).id]
    entity = TransactionDataEntity.new(accounts: included_ids)
    data = entity.data

    ignored_count = Transaction.where(account_id: ignored_ids).count
    assert ignored_count.positive?,
           'There should be at least one transaction for an ignored account ID'

    assert(data[:transactions].all? { |t| included_ids.include?(t[:accountId]) })
    assert(data[:transactions].none? { |t| ignored_ids.include?(t[:accountId]) })
  end

  test 'data returns filtered transactions by users' do
    included_ids = [users(:one).id]
    ignored_ids = [users(:two).id]
    entity = TransactionDataEntity.new(users: included_ids)
    data = entity.data

    ignored_count = Transaction.joins(account: :user)
                               .where(accounts: { user_id: ignored_ids })
                               .count
    assert ignored_count.positive?,
           'There should be at least one transaction for an ignored user ID'

    assert(data[:transactions].all? { |t| included_ids.include?(t[:userId]) })
    assert(data[:transactions].none? { |t| ignored_ids.include?(t[:userId]) })
  end

  test 'data returns filtered transactions by subcategories' do
    included_ids = [subcategories(:restaurant).id]
    ignored_ids = [subcategories(:cash_and_atm).id]
    entity = TransactionDataEntity.new(subcategories: included_ids)
    data = entity.data

    ignored_count = Transaction.where(subcategory_id: ignored_ids).count
    assert ignored_count.positive?,
           'There should be at least one transaction for an ignored subcategory ID'

    assert(data[:transactions].all? { |t| included_ids.include?(t[:subcategory][:id]) })
    assert(data[:transactions].none? { |t| ignored_ids.include?(t[:subcategory][:id]) })
  end

  test 'data returns filtered transactions by search_string for description' do
    description = transactions(:one).description
    entity = TransactionDataEntity.new(search_string: description)
    data = entity.data

    assert data[:meta][:filteredCount].positive?,
           'no transactions found by searching description'
    assert(data[:transactions].all? { |t| t[:description].include?(description) })
  end

  test 'data returns filtered transactions by search_string for amount' do
    amount = transactions(:one).amount.to_s
    entity = TransactionDataEntity.new(search_string: amount)
    data = entity.data

    assert data[:meta][:filteredCount].positive?,
           'no transactions found by searching amount'
    assert(data[:transactions].all? { |t| t[:amount].to_s.include?(amount) })
  end

  test 'data returns filtered transactions by search_string for account institution_name' do
    account = transactions(:one).account
    institution_name = account.institution_name
    entity = TransactionDataEntity.new(search_string: institution_name)
    data = entity.data

    assert data[:meta][:filteredCount].positive?,
           'no transactions found by searching account institution_name'
    assert(data[:transactions].all? do |t|
      Account.find(t[:accountId]).institution_name.include?(institution_name)
    end)
  end

  test 'data returns filtered transactions by search_string for account name' do
    account = transactions(:one).account
    entity = TransactionDataEntity.new(search_string: account.name)
    data = entity.data

    assert data[:meta][:filteredCount].positive?,
           'no transactions found by searching account name'
    assert(data[:transactions].all? { |t| Account.find(t[:accountId]).name.include?(account.name) })
  end

  test 'data returns filtered transactions by search_string for user name' do
    user = transactions(:one).account.user
    entity = TransactionDataEntity.new(search_string: user.name)
    data = entity.data

    assert data[:meta][:filteredCount].positive?,
           'no transactions found by searching user name'
    assert(data[:transactions].all? { |t| User.find(t[:userId]).name.include?(user.name) })
  end

  test 'data returns filtered transactions by search_string for subcategory' do
    subcategory_name = transactions(:one).subcategory.name
    entity = TransactionDataEntity.new(search_string: subcategory_name)
    data = entity.data

    assert data[:meta][:filteredCount].positive?,
           'no transactions found by searching subcategory'
    assert(data[:transactions].all? { |t| t[:subcategory][:name].include?(subcategory_name) })
  end

  test 'data returns no transactions for overfiltered search_string' do
    search_string = 'abcdegfhijklmnopqrstuvqxyz'
    entity = TransactionDataEntity.new(search_string: search_string)
    data = entity.data

    assert_equal 0, data[:meta][:filteredCount]
    assert_equal [], data[:transactions]
  end

  test 'data returns the correct counts' do
    user_ids = [users(:one).id]
    count = Transaction
            .includes(:account, { account: :user })
            .references(:account)
            .where(accounts: { user_id: user_ids })
            .count
    entity = TransactionDataEntity.new(users: user_ids)
    data = entity.data

    assert_equal count, data[:meta][:filteredCount]
    assert_equal Transaction.count, data[:meta][:totalCount]
  end
end
