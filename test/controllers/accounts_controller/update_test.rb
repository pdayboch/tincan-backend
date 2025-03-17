# frozen_string_literal: true

require 'test_helper'
require 'support/mock_statement_parser'

class AccountsControllerUpdateTest < ActionDispatch::IntegrationTest
  test 'updates account successfully through AccountServices::Update' do
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

  test 'returns unprocessable entity error with invalid manualAccountProvider' do
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

  test 'returns unprocessable entity error when nullifying provider on maunual account' do
    account = accounts(:manual_account_only)

    patch account_url(account), params: {
      manualAccountProvider: nil
    }

    assert_response :unprocessable_entity

    json_response = response.parsed_body
    expected_errors = [{
      'field' => 'manualAccountProvider',
      'message' => 'manualAccountProvider cannot be removed from a manual account.'
    }]
    assert_equal(expected_errors, json_response['errors'])
  end

  test 'returns unprocessable entity error with invalid account attributes' do
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
end
