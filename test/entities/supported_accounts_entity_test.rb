# frozen_string_literal: true

require 'test_helper'
require 'support/mock_statement_parser'

class SupportedAccountsEntityTest < ActiveSupport::TestCase
  setup do
    @entity = SupportedAccountsEntity.new
    # Temporarily redefine descendants method to isolate test environment
    StatementParser::Base.singleton_class.class_eval do
      alias_method :original_descendants, :descendants
      define_method(:descendants) { [StatementParser::MockStatementParser] }
    end
  end

  test 'test data returns correct values' do
    expected_data = [
      {
        accountProvider: 'MockStatementParser',
        institutionName: 'Dummy Bank',
        accountName: 'Dummy Account',
        accountType: 'assets',
        accountSubtype: 'cash'
      }
    ]

    assert_equal expected_data, @entity.data
  end

  test 'test provider_from_class returns correct provider' do
    assert_equal 'MockStatementParser',
                 SupportedAccountsEntity.provider_from_class(StatementParser::MockStatementParser)
  end

  test 'test class_from_provider returns correct class' do
    assert_equal StatementParser::MockStatementParser,
                 SupportedAccountsEntity.class_from_provider('MockStatementParser')
  end

  test 'test invalid class_from_provider raises invalid parser error' do
    assert_raises(InvalidParser) do
      SupportedAccountsEntity.class_from_provider('NonExistentProvider')
    end
  end
end
