# frozen_string_literal: true

require 'test_helper'
require 'support/mock_statement_parser'

module AccountServices
  class UpdateTest < ActiveSupport::TestCase
    test 'should update account successfully when only active status updated' do
      account = accounts(:manual_account_only)
      original_attributes = account.attributes.dup

      params = {
        active: !original_attributes['active']
      }
      service = AccountServices::Update.new(account, params)
      result = service.call

      assert_equal !original_attributes['active'], result.active
      assert_equal original_attributes['user_id'], result.user_id
      assert_equal original_attributes['institution_name'], result.institution_name
      assert_equal original_attributes['name'], result.name
      assert_equal original_attributes['account_type'], result.account_type
      assert_equal original_attributes['account_subtype'], result.account_subtype
      assert_equal original_attributes['parser_class'], result.parser_class

      account.reload
      assert_equal !original_attributes['active'], account.active
      assert_equal original_attributes['user_id'], account.user_id
      assert_equal original_attributes['institution_name'], account.institution_name
      assert_equal original_attributes['name'], account.name
      assert_equal original_attributes['account_type'], account.account_type
      assert_equal original_attributes['account_subtype'], account.account_subtype
      assert_equal original_attributes['parser_class'], account.parser_class
    end

    test 'should update account successfully when manual_account_provider updated' do
      account = accounts(:manual_account_only)
      original_attributes = account.attributes.dup

      params = {
        manual_account_provider: 'MockStatementParser'
      }
      service = AccountServices::Update.new(account, params)
      result = service.call

      parser = StatementParser::MockStatementParser

      assert_equal original_attributes['active'], result.active
      assert_equal original_attributes['user_id'], result.user_id
      assert_equal parser::INSTITUTION_NAME, result.institution_name
      assert_equal parser::ACCOUNT_NAME, result.name
      assert_equal parser::ACCOUNT_TYPE, result.account_type
      assert_equal parser::ACCOUNT_SUBTYPE, result.account_subtype
      assert_equal 'MockStatementParser', result.parser_class

      account.reload
      assert_equal original_attributes['active'], account.active
      assert_equal original_attributes['user_id'], account.user_id
      assert_equal parser::INSTITUTION_NAME, account.institution_name
      assert_equal parser::ACCOUNT_NAME, account.name
      assert_equal parser::ACCOUNT_TYPE, account.account_type
      assert_equal parser::ACCOUNT_SUBTYPE, account.account_subtype
      assert_equal 'MockStatementParser', account.parser_class
    end

    test 'should update plaid account successfully when manual_account_provider updated' do
      account = accounts(:plaid_savings_account)
      original_attributes = account.attributes.dup

      params = {
        manual_account_provider: 'MockStatementParser'
      }
      service = AccountServices::Update.new(account, params)
      result = service.call

      assert_equal original_attributes['active'], result.active
      assert_equal original_attributes['user_id'], result.user_id
      assert_equal original_attributes['institution_name'], result.institution_name
      assert_equal original_attributes['name'], result.name
      assert_equal original_attributes['account_type'], result.account_type
      assert_equal original_attributes['account_subtype'], result.account_subtype
      assert_equal 'MockStatementParser', result.parser_class

      account.reload
      assert_equal original_attributes['active'], account.active
      assert_equal original_attributes['user_id'], account.user_id
      assert_equal original_attributes['institution_name'], account.institution_name
      assert_equal original_attributes['name'], account.name
      assert_equal original_attributes['account_type'], account.account_type
      assert_equal original_attributes['account_subtype'], account.account_subtype
      assert_equal 'MockStatementParser', account.parser_class
    end

    test 'should raise InvalidParser when invalid account provider' do
      account = accounts(:manual_account_only)

      params = {
        manual_account_provider: 'InvalidProvider'
      }
      service = AccountServices::Update.new(account, params)
      error = assert_raises InvalidParser do
        service.call
      end

      assert_equal('InvalidProvider', error.message)
    end

    test 'should raise UnprocessableEntityError on account model errors' do
      account = accounts(:manual_account_only)
      params = {
        user_id: -1
      }

      service = AccountServices::Update.new(account, params)
      error = assert_raises UnprocessableEntityError do
        service.call
      end

      expected_errors = [{
        field: 'user',
        message: 'user must exist'
      }]
      assert_equal expected_errors, error.errors
    end
  end
end
