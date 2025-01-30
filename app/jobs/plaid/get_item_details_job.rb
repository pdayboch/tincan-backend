# frozen_string_literal: true

module Plaid
  class GetItemDetailsJob
    include Sidekiq::Worker
    queue_as :default
    sidekiq_options retry: 5

    def perform(plaid_item_id)
      @item = PlaidItem.find_by(item_id: plaid_item_id)
      return unless @item

      update_item!
      sync_institution_name_to_accounts!
    end

    private

    def update_item!
      @item.institution_id = item_details.institution_id
      @item.institution_name = institution_details.name
      @item.save!
    end

    def sync_institution_name_to_accounts!
      return unless @item.accounts.any?

      @item.accounts.update_all(institution_name: @item.institution_name)
    end

    def item_details
      @item_details ||= PlaidServices::Api.new(@item.access_key)
                                          .show
                                          .item
    end

    def institution_details
      @institution_details ||= PlaidServices::Api.institution_get(@item.institution_id)
                                                 .institution
    end
  end
end
