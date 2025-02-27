# frozen_string_literal: true

# == Schema Information
#
# Table name: transactions
#
#  id                         :bigint           not null, primary key
#  transaction_date           :date             not null
#  amount                     :decimal(10, 2)   not null
#  description                :text
#  account_id                 :bigint           not null
#  statement_id               :bigint
#  category_id                :bigint           not null
#  subcategory_id             :bigint           not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  notes                      :text
#  statement_description      :text
#  statement_transaction_date :date
#  split_from_id              :bigint
#  has_splits                 :boolean          default(FALSE), not null
#
require 'test_helper'

class TransactionCreateTest < ActiveSupport::TestCase
  test 'create transaction applies categorization rule with no subcategory specified' do
    account = accounts(:one)
    subcategory = subcategories(:restaurant)
    category = subcategory.category

    rule = CategorizationRule.create!(
      category_id: category.id,
      subcategory_id: subcategory.id
    )

    CategorizationCondition.create!(
      categorization_rule_id: rule.id,
      transaction_field: 'description',
      match_type: 'exactly',
      match_value: 'Venda'
    )

    t = Transaction.create!(
      transaction_date: Date.new(2024, 9, 10),
      amount: 10.00,
      description: 'Venda',
      account_id: account.id
    )

    assert_equal t.reload.subcategory.id, subcategory.id
    assert_equal t.category.id, category.id
  end

  test 'create transaction applies categorization rule when uncategorized subcategory specified' do
    account = accounts(:one)
    rule_subcategory = subcategories(:restaurant)
    rule_category = rule_subcategory.category
    initial_subcategory = subcategories(:uncategorized)

    rule = CategorizationRule.create!(
      category_id: rule_category.id,
      subcategory_id: rule_subcategory.id
    )

    CategorizationCondition.create!(
      categorization_rule_id: rule.id,
      transaction_field: 'description',
      match_type: 'exactly',
      match_value: 'Venda'
    )

    t = Transaction.create!(
      transaction_date: Date.new(2024, 9, 10),
      amount: 10.00,
      description: 'Venda',
      account_id: account.id,
      subcategory_id: initial_subcategory.id
    )

    assert_equal t.subcategory.id, rule_subcategory.id
    assert_equal t.category.id, rule_subcategory.category_id
  end

  test 'create transaction does not apply categorization rule when subcategory specified' do
    account = accounts(:one)
    rule_subcategory = subcategories(:restaurant)
    rule_category = rule_subcategory.category
    actual_subcategory = subcategories(:cash_and_atm)

    rule = CategorizationRule.create!(
      category_id: rule_category.id,
      subcategory_id: rule_subcategory.id
    )

    CategorizationCondition.create!(
      categorization_rule_id: rule.id,
      transaction_field: 'description',
      match_type: 'exactly',
      match_value: 'Venda'
    )

    t = Transaction.create!(
      transaction_date: Date.new(2024, 9, 10),
      amount: 10.00,
      description: 'Venda',
      account_id: account.id,
      subcategory_id: actual_subcategory.id
    )

    assert_equal t.subcategory.id, actual_subcategory.id
    assert_equal t.category.id, actual_subcategory.category_id
  end

  test 'create transaction applies uncategorized with no matching rule and no subcategory specified' do
    account = accounts(:one)
    subcategory = subcategories(:uncategorized)
    category = subcategory.category

    t = Transaction.create!(
      transaction_date: Date.new(2024, 7, 2),
      amount: 9.99,
      description: 'CVS',
      account_id: account.id
    )

    assert_equal t.subcategory.id, subcategory.id
    assert_equal t.category.id, category.id
  end

  test 'create transaction syncs the category with subcategory' do
    account = accounts(:one)
    subcategory = subcategories(:restaurant)
    transaction = Transaction.create(
      transaction_date: 1.day.ago,
      amount: 5.00,
      description: 'new transaction',
      account_id: account.id,
      subcategory_id: subcategory.id
    )

    assert_equal transaction.category_id, subcategory.category_id
  end

  test 'creating transaction with nil description is invalid' do
    account = accounts(:one)

    transaction = Transaction.new(
      transaction_date: Date.new(2024, 11, 5),
      amount: 100.00,
      account_id: account.id
    )

    assert_not transaction.valid?, 'Transaction should be invalid with a missing description'
    assert_includes transaction.errors[:description], 'is required and must have a minimum of three characters'
  end

  test 'creating transaction with description less than 3 characters is invalid' do
    account = accounts(:one)

    transaction = Transaction.new(
      transaction_date: Date.new(2024, 11, 5),
      amount: 100.00,
      description: 'a',
      account_id: account.id
    )

    assert_not transaction.valid?, 'Transaction should be invalid with a short description'
    assert_includes transaction.errors[:description], 'is required and must have a minimum of three characters'
  end
end
