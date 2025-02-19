# frozen_string_literal: true

require 'test_helper'

module PlaidServices
  module Item
    class SyncServiceTest < ActiveSupport::TestCase
      test 'correctly sets item attributes' do
        item = plaid_items(:new_item)
        institution_id = 'ins_1234'
        item.update(institution_id: institution_id)

        item_data = Plaid::ItemGetResponse.new(
          item: Plaid::ItemWithConsentFields.new(
            {
              item_id: item.id,
              institution_id: institution_id,
              billed_products: ['transactions'],
              products: %w[transactions investments],
              consented_data_scopes: ['account_and_balance_info']
            }
          )
        )

        PlaidServices::Api.expects(:institution_get)
                          .with(institution_id)
                          .never

        PlaidServices::Item::SyncService.new(item)
                                        .call(item_data.item)

        assert_equal ['transactions'], item.reload.billed_products
        assert_equal %w[transactions investments], item.products
        assert_equal ['account_and_balance_info'], item.consented_data_scopes
      end

      test 'correctly sets institution details if not set' do
        item = plaid_items(:new_item)
        assert_nil item.institution_id, 'institution_id must be empty for this test'
        assert_nil item.institution_name, 'institution_name must be empty for this test'

        institution_id = 'ins_1234'
        institution_name = 'test bank'
        item_data = Plaid::ItemGetResponse.new(
          item: Plaid::ItemWithConsentFields.new(
            {
              item_id: item.id,
              institution_id: institution_id,
              billed_products: ['transactions'],
              products: %w[transactions investments],
              consented_data_scopes: ['account_and_balance_info']
            }
          )
        )

        institution_data = Plaid::InstitutionsGetByIdResponse.new(
          institution: Plaid::Institution.new(
            name: institution_name
          )
        )

        PlaidServices::Api.expects(:institution_get)
                          .with(institution_id)
                          .returns(institution_data)

        PlaidServices::Item::SyncService.new(item)
                                        .call(item_data.item)

        assert_equal institution_id, item.reload.institution_id
        assert_equal institution_name, item.institution_name
      end

      test 'raises argumentError when plaid_item is incorrect type' do
        expected_msg = 'plaid_item must be of type PlaidItem: String'
        error = assert_raises ArgumentError do
          PlaidServices::Item::SyncService.new('string')
        end

        assert_equal expected_msg, error.message
      end
    end
  end
end
