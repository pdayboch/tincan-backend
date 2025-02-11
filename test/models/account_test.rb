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
require 'test_helper'
require 'support/mock_statement_parser'

class AccountTest < ActiveSupport::TestCase
  test 'should not allow deletion of non-deletable accounts' do
    account = accounts(:non_deletable_account)
    assert_not account.deletable, 'Account is marked as deletable'

    # Attempt to delete the account and assert that destroy returns false
    assert_not account.destroy, 'Account was deleted dispite being non-deletable'

    # Reload the account from the database and assert that it still exists
    assert_not_nil Account.find_by(id: account.id), 'Account was deleted despite being non-deletable'
  end

  test 'active scope should return only active accounts' do
    active_accounts = Account.active

    # Assert that the active scope returns only the active accounts
    assert_includes active_accounts, accounts(:one),
                    'Active account one is not included in the active scope'
    assert_includes active_accounts, accounts(:two),
                    'Active account two is not included in the active scope'
    assert_includes active_accounts, accounts(:three),
                    'Active account three is not included in the active scope'
    assert_includes active_accounts, accounts(:non_deletable_account),
                    'Non-deletable active account is not included in the active scope'
    assert_not_includes active_accounts, accounts(:inactive_account),
                        'Inactive account is included in the active scope'
  end

  test 'statement_parser returns correct statement parser object' do
    user = users(:one)
    account = Account.create(
      user_id: user.id,
      institution_name: StatementParser::MockStatementParser::INSTITUTION_NAME,
      name: StatementParser::MockStatementParser::ACCOUNT_NAME,
      account_type: StatementParser::MockStatementParser::ACCOUNT_TYPE,
      account_subtype: StatementParser::MockStatementParser::ACCOUNT_SUBTYPE,
      parser_class: 'MockStatementParser'
    )

    StatementParser::MockStatementParser
      .expects(:new)
      .with { |arg| arg == 'dummy/path' }
      .returns('statement parser')

    parser = account.statement_parser('dummy/path')
    assert_equal 'statement parser', parser
  end

  test 'statement_parser returns nil if parser_class nil' do
    user = users(:one)
    account = Account.create(
      user_id: user.id,
      institution_name: StatementParser::MockStatementParser::INSTITUTION_NAME,
      name: StatementParser::MockStatementParser::ACCOUNT_NAME,
      account_type: StatementParser::MockStatementParser::ACCOUNT_TYPE,
      account_subtype: StatementParser::MockStatementParser::ACCOUNT_SUBTYPE
    )

    parser = account.statement_parser('dummy/path')
    assert_nil parser
  end
end
