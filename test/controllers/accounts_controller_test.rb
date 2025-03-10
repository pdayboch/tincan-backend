# frozen_string_literal: true

require 'test_helper'
require 'support/mock_statement_parser'

class AccountsControllerTest < ActionDispatch::IntegrationTest
  test 'should get index from AccountDataEntity' do
    original_new = AccountDataEntity.method(:new)

    AccountDataEntity.expects(:new).returns(original_new.call)

    get accounts_url

    assert_response :success
  end

  test 'should create account with AccountServices::create' do
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
    assert response_body['manualAccountEnabled']
    assert_not response_body['plaidAccountEnabled']
  end

  test 'should return error with invalid manualAccountProvider create account' do
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

  test 'should update account through AccountServices::Update' do
    account = accounts(:one)
    mock_updated_account = Account.new(id: account.id, active: false)

    mock_service = mock
    mock_service.expects(:call).returns(mock_updated_account)

    AccountServices::Update.expects(:new)
                           .with(instance_of(Account), kind_of(ActionController::Parameters))
                           .returns(mock_service)

    patch account_url(account), params: {
      active: false
    }

    assert_response :success
    response_body = response.parsed_body
    assert_equal account.id, response_body['id']
    assert_not response_body['active']
  end

  test 'should return unprocessable entity on update with invalid account provider' do
    account = accounts(:one)

    patch account_url(account), params: {
      manualAccountProvider: 'InvalidProvider'
    }

    assert_response :unprocessable_entity

    json_response = response.parsed_body
    expected_errors = [{
      'field' => 'manualAccountProvider',
      'message' => "manualAccountProvider 'InvalidProvider' is not a valid value."
    }]
    assert_equal(expected_errors, json_response['errors'])
  end

  test 'should return unprocessable entity when update fails due to invalid user_id' do
    account = accounts(:one)

    patch account_url(account), params: {
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

  test 'should destroy manual account' do
    account = accounts(:one)

    assert_difference('Account.count', -1) do
      delete account_url(account)
    end

    assert_response :no_content
  end

  test 'should return error when attempting to delete a plaid account' do
    account = plaid_items(:with_multiple_accounts).accounts.first

    assert_no_difference('Account.count') do
      delete account_url(account)
    end

    assert_response :bad_request

    json_response = response.parsed_body
    expected_error = {
      'field' => 'account',
      'message' => 'Plaid accounts cannot be deleted at this time'
    }
    assert_includes json_response['errors'], expected_error
  end
end
