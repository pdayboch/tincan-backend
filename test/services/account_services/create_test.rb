# frozen_string_literal: true

require 'test_helper'
require 'support/mock_statement_parser'

module AccountServices
  class CreateTest < ActiveSupport::TestCase
    test 'should create account successfully' do
      user = users(:one)
      params = {
        manual_account_provider: 'MockStatementParser',
        user_id: user.id
      }

      service = AccountServices::Create.new(params)
      assert_difference 'Account.count', 1 do
        result = service.call
        assert result.id.present?
        assert_equal 'Dummy Bank', result.institution_name
        assert_equal 'Dummy Account', result.name
        assert_equal 'assets', result.account_type
        assert_equal 'cash', result.account_subtype
      end
    end

    test 'should raise UnprocessableEntityError on invalid account provider' do
      user = users(:one)
      params = {
        manual_account_provider: 'InvalidProvider',
        user_id: user.id
      }

      service = AccountServices::Create.new(params)
      error = assert_raises UnprocessableEntityError do
        service.call
      end
      expected_errors = [{
        field: 'manualAccountProvider',
        message: "manualAccountProvider 'InvalidProvider' is not a valid value."
      }]
      assert_equal(expected_errors, error.errors)
    end

    test 'should raise UnprocessableEntityError on account model errors' do
      params = {
        manual_account_provider: 'MockStatementParser'
      }

      service = AccountServices::Create.new(params)
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
