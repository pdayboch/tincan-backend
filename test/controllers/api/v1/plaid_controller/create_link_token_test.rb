# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class PlaidControllerCreateLinkTokenTest < ActionDispatch::IntegrationTest
      test 'create_link_token returns forbidden without user' do
        post api_v1_plaid_create_link_token_url

        assert_response :forbidden
      end

      test 'create_link_token calls correct api and returns response' do
        user = users(:one)
        PlaidServices::Api.expects(:create_link_token)
                          .with { |arg| arg == user }
                          .returns('test-link-token')
        post api_v1_plaid_create_link_token_url, params: { userId: user.id }
        assert_equal({ 'linkToken' => 'test-link-token' }, response.parsed_body)
        assert_response :ok
      end

      test 'create_link_token retuns bad_request on Plaid ApiError' do
        user = users(:one)
        server_error = Plaid::ApiError.new(
          response_body: {
            'error_type' => 'SERVER_ERROR'
          }
        )
        PlaidServices::Api.expects(:create_link_token)
                          .with { |arg| arg == user }
                          .raises(server_error)
        post api_v1_plaid_create_link_token_url, params: { userId: user.id }
        assert_equal({ 'error' => 'Invalid request' }, response.parsed_body)
        assert_response :bad_request
      end
    end
  end
end
