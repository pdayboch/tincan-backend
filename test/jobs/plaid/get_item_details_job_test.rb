# frozen_string_literal: true

require 'test_helper'

module Plaid
  class GetItemDetailsJobTest < ActiveSupport::TestCase
    test 'successfully sets the item institution details' do
      item = plaid_items(:new_item)

      assert_nil item.institution_id, 'institution_id must be empty for this test'
      assert_nil item.institution_name, 'institution_name must be empty for this test'

      institution_id = 'ins_1234'

      plaid_api = mock('plaid_api')
      PlaidServices::Api.stubs(:new).returns(plaid_api)
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
      plaid_api.expects(:show).returns(item_data)

      institution_data = Plaid::InstitutionsGetByIdResponse.new(
        institution: Plaid::Institution.new(
          name: 'test bank'
        )
      )
      PlaidServices::Api.expects(:institution_get)
                        .with(institution_id)
                        .returns(institution_data)

      assert_no_changes lambda {
        item.reload.attributes.except(
          'institution_id',
          'institution_name',
          'billed_products',
          'products',
          'consented_data_scopes',
          'updated_at'
        )
      } do
        Plaid::GetItemDetailsJob.new.perform(item.item_id)
      end
      assert_equal institution_id, item.reload.institution_id
      assert_equal 'test bank', item.institution_name
      assert_equal ['transactions'], item.billed_products
      assert_equal %w[transactions investments], item.products
      assert_equal ['account_and_balance_info'], item.consented_data_scopes
    end

    test 'syncs institution_name to accounts if any' do
      item = plaid_items(:with_multiple_accounts)

      assert_nil item.institution_name, 'institution_name must be empty for this test'
      item.accounts.each do |a|
        assert_nil a.institution_name, 'all accounts must have empty institution_name'
      end

      institution_id = 'ins_1234'
      institution_name = 'test bank name'

      plaid_api = mock('plaid_api')
      PlaidServices::Api.stubs(:new).returns(plaid_api)
      item_data = Plaid::ItemGetResponse.new(
        item: Plaid::ItemWithConsentFields.new(
          {
            item_id: item.id,
            institution_id: institution_id
          }
        )
      )
      plaid_api.expects(:show).returns(item_data)

      institution_data = Plaid::InstitutionsGetByIdResponse.new(
        institution: Plaid::Institution.new(
          name: institution_name
        )
      )
      PlaidServices::Api.expects(:institution_get)
                        .with(institution_id)
                        .returns(institution_data)

      Plaid::GetItemDetailsJob.new.perform(item.item_id)
      item.reload.accounts.each do |a|
        assert_equal institution_name, a.institution_name
      end
    end

    test 'exits gracefully when plaid_item does not exist' do
      assert_nothing_raised do
        Plaid::GetItemDetailsJob.new.perform(0)
      end
    end
  end
end
