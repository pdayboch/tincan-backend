# frozen_string_literal: true

require 'test_helper'

class AccountsControllerTest < ActionDispatch::IntegrationTest
  test 'should get index' do
    get accounts_url
    assert_response :success
  end

  test 'should get index from AccountDataEntity' do
    original_new = AccountDataEntity.method(:new)

    AccountDataEntity.expects(:new).returns(original_new.call)

    get accounts_url
  end

  test 'should create account' do
    account = accounts(:one)

    assert_difference('Account.count') do
      post accounts_url, params: {
        accountProvider: 'ChaseFreedomCreditCard',
        userId: account.user_id
      }
    end

    assert_response :created
  end

  test 'should return error with invalid accountProvider create account' do
    account = accounts(:one)

    post accounts_url, params: {
      accountProvider: 'NonExistantProvider',
      userId: account.user_id
    }

    assert_response :unprocessable_entity
    json_response = response.parsed_body

    expected_error = {
      'field' => 'accountProvider',
      'message' => "accountProvider 'NonExistantProvider' is not a valid value."
    }

    assert_includes json_response['errors'], expected_error
  end

  test 'should update account' do
    account = accounts(:one)

    patch account_url(account), params: {
      active: false
    }

    assert_response :success
    account.reload
    assert_equal account.active, false, 'Account was not updated'

    json_response = response.parsed_body
    assert_equal account.id, json_response['id']
    assert_equal account.active, json_response['active']
  end

  test 'should return error when updating account with disallowed params' do
    account = accounts(:one)

    patch account_url(account), params: {
      accountProvider: 'BarclaysViewCreditCard'
    }

    assert_response :unprocessable_entity
    json_response = response.parsed_body

    expected_error = {
      'field' => 'accountProvider',
      'message' => 'accountProvider cannot be updated after account creation.'
    }

    assert_includes json_response['errors'], expected_error
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

  test 'should destroy account' do
    account = accounts(:one)

    assert_difference('Account.count', -1) do
      delete account_url(account)
    end

    assert_response :no_content
  end
end
