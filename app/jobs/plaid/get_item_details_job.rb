# frozen_string_literal: true

module Plaid
  class GetItemDetailsJob
    include Sidekiq::Worker
    queue_as :default
    sidekiq_options retry: 5

    def perform(plaid_item_id)
      local_item = PlaidItem.find_by(item_id: plaid_item_id)
      return unless local_item

      details = item_details(local_item.access_key)
      local_item.institution_id = details[:item][:institution_id]
      local_item.save!
    end

    private

    def item_details(access_key)
      PlaidServices::Api.new(access_key).show.to_hash
    end
  end
end
