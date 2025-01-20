# frozen_string_literal: true

require 'test_helper'

module PlaidServices
  class ApiTest < ActiveSupport::TestCase
    test 'successfully creates plaid item' do
      user = users(:one)
      plaid_response = { access_token: 'test-access-token', item_id: 'test-item-id' }

      PlaidServices::Api.stub(:public_token_exchange, plaid_response) do
        assert_difference 'PlaidItem.count', 1 do
          result = ItemCreate.new('test-public-token', user).call
          assert result

          plaid_item = PlaidItem.last
          assert_equal plaid_response[:access_token], plaid_item.access_key
          assert_equal plaid_response[:item_id], plaid_item.item_id
          assert_equal user.id, plaid_item.user_id
        end
      end
    end

    test 'raises error and destroys plaid item for duplicate item id' do
      user = users(:one)
      existing_item = plaid_items(:one)
      plaid_response = {
        access_token: 'test-access-token',
        item_id: existing_item.item_id
      }

      api_mock = Minitest::Mock.new
      api_mock.expect(:destroy, true)

      PlaidServices::Api.stub :new, lambda { |access_token|
        assert_equal plaid_response[:access_token], access_token, 'API should be initialized with the correct access token'
        api_mock
      } do
        PlaidServices::Api.stub(:public_token_exchange, plaid_response) do
          error = assert_raises(ItemCreate::Error) do
            ItemCreate.new('test-public-token', user).call
          end
          assert_equal 'This institution has already been connected', error.message
        end
      end
      assert_mock api_mock
    end

    test 'logs error with item id when destroy item attempt fails' do
      user = users(:one)
      existing_item = plaid_items(:one)
      plaid_response = {
        access_token: 'test-access-token',
        item_id: existing_item.item_id
      }

      api_server_error_body = {
        'error_type' => 'TRANSACTIONS_ERROR',
        'error_code' => Api::MUTATION_ERROR,
        'error_message' => 'Underlying transaction data changed since last page was fetched.',
        'request_id' => '12345',
        'documentation_url' => 'https://plaid.com/docs'
      }.to_json
      api_server_error = Plaid::ApiError.new(response_body: api_server_error_body)

      PlaidServices::Api.stub(:public_token_exchange, plaid_response) do
        api_mock = Minitest::Mock.new
        api_mock.expect(:destroy, nil) do
          raise api_server_error
        end

        logger_mock = Minitest::Mock.new
        logger_mock.expect(:error, nil, ["Failed to destroy Plaid item id: #{existing_item.item_id}"])

        Rails.stub(:logger, logger_mock) do
          PlaidServices::Api.stub(:new, api_mock) do
            assert_raises(ItemCreate::Error) do
              ItemCreate.new('test-public-token', user).call
            end
          end
        end

        assert_mock logger_mock
        assert_mock api_mock
      end
    end

    test 'raises error for nil public token' do
      user = users(:one)
      assert_raises(ArgumentError) do
        ItemCreate.new(nil, user).call
      end
    end

    test 'raises error for blank public token' do
      user = users(:one)
      assert_raises(ArgumentError) do
        ItemCreate.new('', user).call
      end
    end

    test 'raises error for nil user' do
      assert_raises(ArgumentError) do
        ItemCreate.new('test-public-token', nil).call
      end
    end
  end
end
