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
#  merchant_name              :string
#  pending                    :boolean          default(FALSE)
#  plaid_transaction_id       :string
#
class Transaction < ApplicationRecord
  belongs_to :account
  belongs_to :statement, optional: true
  belongs_to :category
  belongs_to :subcategory

  # If this transaction is a split, it will reference a parent transaction
  belongs_to :parent_transaction,
             class_name: 'Transaction',
             foreign_key: 'split_from_id',
             optional: true,
             inverse_of: :splits

  # A transaction can have many splits if it's a parent
  has_many :splits,
           class_name: 'Transaction',
           foreign_key: 'split_from_id',
           dependent: :nullify,
           inverse_of: :parent_transaction

  before_validation :set_default_category_and_subcategory, on: :create
  before_validation :sync_category_with_subcategory,
                    if: -> { subcategory_id.present? }

  validates :description, length: {
    minimum: 3,
    message: 'is required and must have a minimum of three characters'
  }
  validates :transaction_date, presence: true

  after_create :apply_categorization_rule

  private

  def apply_categorization_rule
    # Only apply the categorization rule if the subcategory is "Uncategorized"
    return unless subcategory_id == uncategorized_subcategory_id

    matched_rule = CategorizationRule.all.find { |rule| rule.match?(self) }
    return unless matched_rule

    self.category = matched_rule.category
    self.subcategory = matched_rule.subcategory
  end

  def set_default_category_and_subcategory
    self.subcategory_id ||= uncategorized_subcategory_id
    self.category = subcategory.category
  end

  # Ensure that the category is in sync with the subcategory
  def sync_category_with_subcategory
    self.category = subcategory.category
  end

  def uncategorized_subcategory_id
    @uncategorized_subcategory_id ||= Subcategory.find_by!(name: 'Uncategorized').id
  end
end
