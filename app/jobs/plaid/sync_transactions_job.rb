# frozen_string_literal: true

module Plaid
  class SyncTransactionsJob
    include Sidekiq::Worker
    include Sidekiq::Status::Worker

    sidekiq_options retry: 2

    SYNC_PERIOD = 12.hours

    # @param override_item_ids [Array<String>, nil] optional item_ids to sync transactions.
    # To sync for all items that need a transactions sync, pass nil
    def perform(override_item_ids = nil)
      @override_item_ids = override_item_ids
      @category_mapper = Plaid::CategoryMapper.new
      catch(:rate_limit_exceeded) do
        items_to_sync.find_each(batch_size: 50) { |item| process_item(item) }
      end
    end

    private

    def process_item(item)
      PlaidItem.transaction do
        item.lock!
        PlaidServices::Transactions::SyncService.new(
          item,
          category_mapper: @category_mapper
        ).call
      rescue Plaid::ApiRateLimitError
        Rails.logger.warn('Plaid API rate limit exceeded. Stopping job.')
        throw :rate_limit_exceeded
      end
    end

    def items_to_sync
      base_scope.lock('FOR UPDATE SKIP LOCKED')
    end

    def base_scope
      if @override_item_ids
        PlaidItem.where(item_id: @override_item_ids)
      else
        items_needing_transaction_sync
      end
    end

    def items_needing_transaction_sync
      PlaidItem
        .where.not(accounts_synced_at: nil)
        .where('transactions_synced_at IS NULL OR transactions_synced_at < ?', SYNC_PERIOD.ago)
    end
  end
end
