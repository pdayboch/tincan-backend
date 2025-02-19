# frozen_string_literal: true

require 'test_helper'

module PlaidServices
  module Item
    class CreateServiceTest < ActiveSupport::TestCase
      setup do
        # Ensure jobs are enqueued but not performed
        Sidekiq::Testing.fake!
      end

      teardown do
        Sidekiq::Worker.clear_all
      end

      test 'successfully creates plaid item' do
        user = users(:one)
        plaid_response = Plaid::ItemPublicTokenExchangeResponse.new(
          {
            access_token: 'test-access-token',
            item_id: 'test-item-id'
          }
        )

        PlaidServices::Api.stub(:public_token_exchange, plaid_response) do
          assert_difference 'PlaidItem.count', 1 do
            CreateService.new('test-public-token', user).call

            plaid_item = PlaidItem.last
            assert_equal 'test-access-token', plaid_item.access_key
            assert_equal 'test-item-id', plaid_item.item_id
            assert_equal user.id, plaid_item.user_id
          end
        end
      end

      test 'returns the job id of the enqueued job' do
        sync_accounts_job_id = SecureRandom.uuid
        user = users(:one)
        plaid_response = Plaid::ItemPublicTokenExchangeResponse.new(
          access_token: 'test-access-token',
          item_id: 'test-item-id'
        )

        Plaid::SyncAccountsJob.stub(:perform_async, sync_accounts_job_id) do
          PlaidServices::Api.stub(:public_token_exchange, plaid_response) do
            result = CreateService.new('test-public-token', user).call

            assert_equal sync_accounts_job_id, result
          end
        end
      end

      test 'successfully enqueues Plaid::SyncAccountsJob with correct item_id' do
        user = users(:one)
        plaid_response = Plaid::ItemPublicTokenExchangeResponse.new(
          {
            access_token: 'test-access-token',
            item_id: 'test-item-id'
          }
        )

        PlaidServices::Api.stub(:public_token_exchange, plaid_response) do
          CreateService.new('test-public-token', user).call
        end

        assert_equal 1, Plaid::SyncAccountsJob.jobs.size, 'Expected one job to be enqueued'
        job_args = Plaid::SyncAccountsJob.jobs.first['args']
        assert_includes job_args, 'test-item-id'
      end

      test 'raises DuplicateItemError error for duplicate item id' do
        user = users(:one)
        existing_item = plaid_items(:new_item)
        plaid_response = Plaid::ItemPublicTokenExchangeResponse.new(
          {
            access_token: 'test-access-token',
            item_id: existing_item.item_id
          }
        )

        PlaidServices::Api.stub(:public_token_exchange, plaid_response) do
          error = assert_raises(CreateService::DuplicateItemError) do
            CreateService.new('test-public-token', user).call
          end
          expected_msg = "Item has already been connected. item_id: #{existing_item.item_id}"
          assert_equal expected_msg, error.message
        end
      end

      test 'raises error for nil public token' do
        user = users(:one)
        assert_raises(ArgumentError) do
          CreateService.new(nil, user).call
        end
      end

      test 'raises error for blank public token' do
        user = users(:one)
        assert_raises(ArgumentError) do
          CreateService.new('', user).call
        end
      end

      test 'raises error for nil user' do
        assert_raises(ArgumentError) do
          CreateService.new('test-public-token', nil).call
        end
      end
    end
  end
end
