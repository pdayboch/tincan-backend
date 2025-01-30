# frozen_string_literal: true

require 'test_helper'

module PlaidServices
  class ApiItemTest < ActiveSupport::TestCase
    setup do
      @plaid_client = mock('plaid_client')

      @error_response = {
        'error_type' => 'API_ERROR',
        'error_code' => 'INTERNAL_SERVER_ERROR',
        'error_message' => 'An internal server error occurred',
        'request_id' => '12345',
        'documentation_url' => 'https://plaid.com/docs'
      }.to_json

      @expected_log = 'Plaid Service Error: ' \
                      'type = API_ERROR; ' \
                      'code = INTERNAL_SERVER_ERROR; ' \
                      'message = An internal server error occurred; ' \
                      'request_id = 12345; ' \
                      'error_code_reason = ; ' \
                      'docs = https://plaid.com/docs;'

      Plaid::ApiClient.stubs(:new).returns(@plaid_client)
      Plaid::PlaidApi.stubs(:new).returns(@plaid_client)
    end

    test 'gets item successfully' do
      service = PlaidServices::Api.new('test-access-token')
      item_response = Plaid::ItemGetResponse.new(
        item: Plaid::ItemWithConsentFields.new(
          {
            item_id: 'test-item-id',
            institution_id: 'ins_1234'
          }
        )
      )

      @plaid_client.expects(:item_get)
                   .with(instance_of(Plaid::ItemGetRequest))
                   .returns(item_response)

      response = service.show

      assert_equal item_response, response
    end

    test 'handles get item error' do
      api_error = Plaid::ApiError.new(response_body: @error_response)

      Rails.logger.expects(:error).with(@expected_log)
      @plaid_client.expects(:item_get).raises(api_error)

      assert_raises Plaid::ApiError do
        PlaidServices::Api.new(@access_token).show
      end
    end

    test 'removes item successfully' do
      service = PlaidServices::Api.new(@access_token)
      remove_response = Plaid::ItemRemoveResponse.new(
        { request_id: 'test-request-id' }
      )

      @plaid_client.expects(:item_remove)
                   .with(instance_of(Plaid::ItemRemoveRequest))
                   .returns(remove_response)

      response = service.destroy

      assert_equal remove_response, response
    end

    test 'handles remove item error' do
      api_error = Plaid::ApiError.new(response_body: @error_response)

      Rails.logger.expects(:error).with(@expected_log)
      @plaid_client.expects(:item_remove).raises(api_error)

      assert_raises Plaid::ApiError do
        PlaidServices::Api.new(@access_token).destroy
      end
    end
  end
end
