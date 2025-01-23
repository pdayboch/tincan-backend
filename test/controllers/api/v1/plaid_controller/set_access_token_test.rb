# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class PlaidControllerSetAccessTokenTest < ActionDispatch::IntegrationTest
      test 'returns forbidden without user' do
        post api_v1_plaid_set_access_token_url, params: {
          publicToken: 'test-public-token'
        }

        assert_response :forbidden
      end

      test 'returns bad request without public token' do
        user = users(:one)

        post api_v1_plaid_set_access_token_url, params: {
          user_id: user.id
        }

        error_resp = { 'errors' => [
          { 'field' => 'publicToken', 'message' => 'publicToken is required' }
        ] }
        assert_equal error_resp, response.parsed_body
        assert_response :bad_request
      end

      test 'calls item create service and returns result' do
        item_create = mock('item_create_service')
        user = users(:one)
        PlaidServices::ItemCreate.expects(:new)
                                 .with { |token, user_arg| token == 'test-public-token' && user_arg == user }
                                 .returns(item_create)

        item_create.expects(:call).returns(true)
        post api_v1_plaid_set_access_token_url, params: {
          userId: user.id,
          publicToken: 'test-public-token'
        }

        assert_equal({ 'status' => true }, response.parsed_body)
        assert_response :ok
      end

      test 'retuns bad_request on Plaid ApiError' do
        user = users(:one)
        server_error = Plaid::ApiError.new(
          response_body: {
            'error_type' => 'SERVER_ERROR'
          }
        )
        PlaidServices::Api.expects(:public_token_exchange)
                          .with { |arg| arg == 'test-public-token' }
                          .raises(server_error)

        post api_v1_plaid_set_access_token_url, params: {
          userId: user.id,
          publicToken: 'test-public-token'
        }

        assert_equal({ 'error' => 'Invalid request' }, response.parsed_body)
        assert_response :bad_request
      end
    end
  end
end
