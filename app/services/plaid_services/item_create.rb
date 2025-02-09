# frozen_string_literal: true

module PlaidServices
  class ItemCreate
    class Error < StandardError; end

    def initialize(public_token, user)
      @public_token = public_token
      @user = user
    end

    def call
      validate_inputs

      token_exchange = PlaidServices::Api.public_token_exchange(@public_token)
      create_plaid_item(token_exchange)
      enqueue_jobs(token_exchange)
      true
    end

    private

    def validate_inputs
      raise ArgumentError, 'Public token cannot be blank' if @public_token.blank?
      raise ArgumentError, 'User cannot be nil' if @user.nil?
    end

    def create_plaid_item(token_exchange)
      PlaidItem.create!(
        access_key: token_exchange.access_token,
        item_id: token_exchange.item_id,
        user_id: @user.id
      )
    rescue ActiveRecord::RecordNotUnique
      destroy_plaid_item(token_exchange)
      raise Error, "Item has already been connected: #{token_exchange.item_id}"
    end

    def enqueue_jobs(token_exchange)
      enqueue_plaid_get_item_details_job(token_exchange.item_id)
      enqueue_plaid_fetch_accounts_job(token_exchange.item_id)
    end

    def enqueue_plaid_get_item_details_job(item_id)
      Plaid::GetItemDetailsJob.perform_async(item_id)
    end

    def enqueue_plaid_fetch_accounts_job(item_id)
      Plaid::SyncAccountsJob.perform_async(item_id)
    end

    # We need to make sure we destroy any Plaid Items on error before we lose
    # the access_token from memory or else we won't be able to destroy it and
    # will continue to get charged for that item.
    # If we can't destroy it, at minimum log the item_id and contact Plaid support.
    def destroy_plaid_item(token_exchange)
      PlaidServices::Api.new(token_exchange.access_token).destroy
    rescue Plaid::ApiError
      Rails.logger.error "Failed to destroy Plaid item id: #{token_exchange.item_id}"
    end
  end
end
