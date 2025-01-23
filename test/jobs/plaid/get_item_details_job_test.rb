# frozen_string_literal: true

require 'test_helper'

module Plaid
  class GetItemDetailsJobTest < ActiveSupport::TestCase
    test 'successfully sets the item institution id' do
      item = plaid_items(:one)

      assert_nil item.institution_id, 'institution_id must be unset for this test'

      plaid_api = mock('plaid_api')
      PlaidServices::Api.stubs(:new).returns(plaid_api)
      mock_item_data = { item_id: item.id, institution_id: 'ins_12' }
      plaid_response = Plaid::ItemGetResponse.new(item: mock_item_data)
      plaid_api.expects(:show).returns(plaid_response)

      assert_no_changes -> { item.reload.attributes.except('institution_id', 'updated_at') } do
        Plaid::GetItemDetailsJob.new.perform(item.item_id)
      end
      assert_equal 'ins_12', item.reload.institution_id
    end

    test 'exits gracefully when plaid_item does not exist' do
      assert_nothing_raised do
        Plaid::GetItemDetailsJob.new.perform(0)
      end
    end
  end
end
