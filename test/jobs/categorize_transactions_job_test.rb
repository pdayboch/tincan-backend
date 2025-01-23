# frozen_string_literal: true

require 'test_helper'

class CategorizeTransactionsJobTest < ActiveSupport::TestCase
  test 'job successfully categorizes transactions based on rules' do
    transaction = transactions(:uncategorized)
    subcategory = subcategories(:restaurant)

    rule = CategorizationRule.create!(
      category: subcategory.category,
      subcategory: subcategory
    )
    CategorizationCondition.create!(
      categorization_rule: rule,
      transaction_field: 'description',
      match_type: 'exactly',
      match_value: transaction.description
    )

    assert_changes -> { transaction.reload.subcategory },
                   to: subcategory do
      CategorizeTransactionsJob.new.perform
    end
  end

  test 'job does not categorize transactions without matching rules' do
    transaction = transactions(:uncategorized)
    subcategory = subcategories(:restaurant)

    rule = CategorizationRule.create!(
      category: subcategory.category,
      subcategory: subcategory
    )
    CategorizationCondition.create!(
      categorization_rule: rule,
      transaction_field: 'description',
      match_type: 'exactly',
      match_value: "#{transaction.description}foo"
    )
    assert_no_changes -> { transaction.reload.subcategory } do
      CategorizeTransactionsJob.new.perform
    end
  end

  test 'job does not recategorize transaction with matching rule' do
    categorized_transaction = transactions(:one)
    rule_subcategory = subcategories(:cash_and_atm)
    assert_not_equal(
      categorized_transaction.subcategory_id,
      rule_subcategory.id,
      'Starting subcategory and rule subcategory must be different for this test'
    )

    rule = CategorizationRule.create!(
      category: rule_subcategory.category,
      subcategory: rule_subcategory
    )
    CategorizationCondition.create!(
      categorization_rule: rule,
      transaction_field: 'description',
      match_type: 'exactly',
      match_value: categorized_transaction.description
    )

    assert_no_changes -> { categorized_transaction.reload.subcategory } do
      CategorizeTransactionsJob.new.perform
    end
  end

  test 'job skips if uncategorized subcategory does not exist' do
    subcategory = subcategories(:uncategorized)
    subcategory.update(name: 'foo')
    transaction = transactions(:uncategorized)

    # Store the original state of the transaction
    original_category = transaction.category
    original_subcategory = transaction.subcategory

    # Create rules that match this transaction
    rule_subcategory = subcategories(:restaurant)

    rule = CategorizationRule.create!(
      category: rule_subcategory.category,
      subcategory: rule_subcategory
    )
    CategorizationCondition.create!(
      categorization_rule: rule,
      transaction_field: 'description',
      match_type: 'exactly',
      match_value: transaction.description
    )

    CategorizeTransactionsJob.new.perform

    transaction.reload
    assert_equal(
      original_category,
      transaction.category,
      'Transaction category should not change'
    )
    assert_equal(
      original_subcategory,
      transaction.subcategory,
      'Transaction subcategory should not change'
    )
  end
end
