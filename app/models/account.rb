# frozen_string_literal: true

# == Schema Information
#
# Table name: accounts
#
#  id                  :bigint           not null, primary key
#  name                :string           not null
#  account_type        :string
#  active              :boolean          default(TRUE)
#  deletable           :boolean          default(TRUE)
#  user_id             :bigint           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  statement_directory :text
#  parser_class        :string
#  plaid_account_id    :string
#  institution_name    :string
#  account_subtype     :string
#  current_balance     :decimal(10, 2)
#  plaid_item_id       :bigint
#
class Account < ApplicationRecord
  belongs_to :user
  belongs_to :plaid_item, optional: true
  has_many :statements, dependent: :destroy
  has_many :transactions, dependent: :destroy

  before_destroy :check_deletable

  scope :active, -> { where(active: true) }

  def statement_parser(file_path)
    "StatementParser::#{parser_class}".constantize.new(file_path) if parser_class.present?
  end

  private

  def check_deletable
    return if deletable

    errors.add(:base, "The #{name} account cannot be deleted.")
    throw(:abort)
  end
end
