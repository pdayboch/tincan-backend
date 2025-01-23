# frozen_string_literal: true

class CategorizeTransactionsJob
  include Sidekiq::Job
  sidekiq_options retry: 3

  def perform
    return unless uncategorized_subcategory_id

    categorization_rules = load_categorization_rules
    process_transactions_in_batches(categorization_rules)
  end

  private

  def uncategorized_subcategory_id
    @uncategorized_subcategory_id ||= Subcategory.find_by(
      name: 'Uncategorized'
    )&.id
  end

  def load_categorization_rules
    CategorizationRule.includes(:categorization_conditions).all
  end

  def process_transactions_in_batches(categorization_rules)
    transaction_query.find_in_batches(batch_size: 1000) do |batch|
      categorize_and_save_transactions(batch, categorization_rules)
    end
  end

  def categorize_and_save_transactions(batch, categorization_rules)
    batch.each do |transaction|
      matched_rule = find_matching_rule(transaction, categorization_rules)
      apply_categorization!(transaction, matched_rule) if matched_rule
    end
  end

  def find_matching_rule(transaction, rules)
    rules.find { |rule| rule.match?(transaction) }
  end

  def apply_categorization!(transaction, matched_rule)
    transaction.category = matched_rule.category
    transaction.subcategory = matched_rule.subcategory
    transaction.save
  end

  def transaction_query
    Transaction
      .where(subcategory_id: uncategorized_subcategory_id)
  end
end
