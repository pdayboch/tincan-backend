# frozen_string_literal: true

require 'test_helper'
require 'support/mock_statement_parser'

class AccountsControllerDestroyTest < ActionDispatch::IntegrationTest
  test 'should destroy manual account' do
    account = accounts(:one)

    assert_difference('Account.count', -1) do
      delete account_url(account)
    end

    assert_response :no_content
  end

  test 'returns bad request error when attempting to delete a plaid account' do
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
