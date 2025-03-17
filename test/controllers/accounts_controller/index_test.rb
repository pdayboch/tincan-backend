# frozen_string_literal: true

require 'test_helper'
require 'support/mock_statement_parser'

class AccountsControllerIndexTest < ActionDispatch::IntegrationTest
  test 'should get index from AccountDataEntity' do
    original_new = AccountDataEntity.method(:new)

    AccountDataEntity.expects(:new).returns(original_new.call)

    get accounts_url

    assert_response :success
  end
end
