# frozen_string_literal: true

module Plaid
  class SyncAccountsJob
    include Sidekiq::Worker
    include Sidekiq::Status::Worker

    sidekiq_options retry: 2

    SYNC_PERIOD = 24.hours

    # @param override_item_ids [Array<String>, nil] optional item_ids to sync accounts.
    # To sync for all items that need an accounts sync, pass nil
    def perform(override_item_ids = nil)
      @override_item_ids = override_item_ids
      catch(:rate_limit_exceeded) do
        items_to_sync.find_each(batch_size: 200) { |item| process_item(item) }
      end
    end

    private

    def process_item(item)
      PlaidItem.transaction do
        item.lock!
        PlaidServices::Accounts::SyncService.new(item).call
      rescue PlaidServices::Accounts::SyncService::PlaidApiRateLimitError
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
        items_needing_account_sync
      end
    end

    def items_needing_account_sync
      PlaidItem
        .where('accounts_synced_at IS NULL OR accounts_synced_at < ?', SYNC_PERIOD.ago)
    end
  end
end
