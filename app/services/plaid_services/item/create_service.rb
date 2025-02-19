# frozen_string_literal: true

module PlaidServices
  module Item
    class CreateService
      class DuplicateItemError < StandardError; end

      def initialize(public_token, user)
        @public_token = public_token
        @user = user
        check_params!
      end

      def call
        token_exchange = PlaidServices::Api.public_token_exchange(@public_token)
        create_plaid_item(token_exchange)
        enqueue_plaid_sync_accounts_job(token_exchange.item_id)
      end

      private

      def create_plaid_item(token_exchange)
        PlaidItem.create!(
          access_key: token_exchange.access_token,
          item_id: token_exchange.item_id,
          user_id: @user.id
        )
      rescue ActiveRecord::RecordNotUnique
        msg = "Item has already been connected. item_id: #{token_exchange.item_id}"
        raise DuplicateItemError, msg
      end

      def enqueue_plaid_sync_accounts_job(item_id)
        Plaid::SyncAccountsJob.perform_async(item_id)
      end

      def check_params!
        raise ArgumentError, 'Public token cannot be blank' if @public_token.blank?
        raise ArgumentError, 'User cannot be nil' if @user.nil?
      end
    end
  end
end
