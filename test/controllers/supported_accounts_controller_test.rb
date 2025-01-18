# frozen_string_literal: true

require 'test_helper'

class SupportedAccountsControllerTest < ActionDispatch::IntegrationTest
  test 'should get index from SupportedAccountsEntity' do
    original_new = SupportedAccountsEntity.method(:new)

    SupportedAccountsEntity.method(:new)

    SupportedAccountsEntity
      .expects(:new)
      .returns(original_new.call)

    get supported_accounts_url

    assert_response :success

    json_response = response.parsed_body
    assert json_response[0]['accountProvider'].present?
    assert json_response[0]['institutionName'].present?
    assert json_response[0]['accountName'].present?
    assert json_response[0]['accountType'].present?
  end
end
