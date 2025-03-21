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

  test 'data returns correct values' do
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

  test 'provider_from_class returns correct provider' do
    assert_equal 'MockStatementParser',
                 SupportedAccountsEntity.provider_from_class(StatementParser::MockStatementParser)
  end

  test 'class_from_provider returns correct class' do
    assert_equal StatementParser::MockStatementParser,
                 SupportedAccountsEntity.class_from_provider('MockStatementParser')
  end

  test 'class_from_provider raises EmptyProviderError when provider is nil' do
    error = assert_raises(EmptyProviderError) do
      SupportedAccountsEntity.class_from_provider(nil)
    end

    assert_equal 'provider cannot be nil', error.message
  end

  test 'class_from_provider raises InvalidParserError with invalid provider' do
    assert_raises(InvalidParserError) do
      SupportedAccountsEntity.class_from_provider('NonExistentProvider')
    end
  end

  test 'class_from_provider raises InvalidParserError with lowercase provider' do
    assert_raises(InvalidParserError) do
      SupportedAccountsEntity.class_from_provider('nonExistentProvider')
    end
  end
end
