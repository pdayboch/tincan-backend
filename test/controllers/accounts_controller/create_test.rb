# frozen_string_literal: true

require 'test_helper'
require 'support/mock_statement_parser'

class AccountsControllerCreateTest < ActionDispatch::IntegrationTest
  test 'creates account successfully' do
    user = users(:one)
    account_provider = 'MockStatementParser'

    assert_difference('Account.count') do
      post accounts_url, params: {
        manualAccountProvider: account_provider,
        userId: user.id
      }
    end

    assert_response :created
    response_body = response.parsed_body
    assert_equal StatementParser::MockStatementParser::INSTITUTION_NAME, response_body['institutionName']
    assert_equal StatementParser::MockStatementParser::ACCOUNT_NAME, response_body['name']
    assert_equal StatementParser::MockStatementParser::ACCOUNT_TYPE, response_body['accountType']
    assert_equal StatementParser::MockStatementParser::ACCOUNT_SUBTYPE, response_body['accountSubtype']
    assert_equal account_provider, response_body['manualAccountProvider']
    assert_not response_body['plaidAccountEnabled']
  end

  test 'returns unprocessable entity error with invalid manualAccountProvider' do
    user = users(:one)

    post accounts_url, params: {
      manualAccountProvider: 'NonExistantProvider',
      userId: user.id
    }

    assert_response :unprocessable_entity
    json_response = response.parsed_body

    expected_error = {
      'field' => 'manualAccountProvider',
      'message' => "manualAccountProvider 'NonExistantProvider' is not a valid value."
    }

    assert_includes json_response['errors'], expected_error
  end

  test 'returns unprocessable entity with nil manualAccountProvider' do
    user = users(:one)

    post accounts_url, params: {
      manualAccountProvider: nil,
      userId: user.id
    }

    assert_response :unprocessable_entity
    json_response = response.parsed_body

    expected_error = {
      'field' => 'manualAccountProvider',
      'message' => 'manualAccountProvider cannot be empty'
    }

    assert_includes json_response['errors'], expected_error
  end

  test 'returns unprocessable entity with invalid account attributes' do
    post accounts_url, params: {
      manualAccountProvider: 'MockStatementParser',
      user_id: -1
    }

    assert_response :unprocessable_entity
    json_response = response.parsed_body

    expected_error = {
      'field' => 'user',
      'message' => 'user must exist'
    }

    assert_includes json_response['errors'], expected_error
  end
end
