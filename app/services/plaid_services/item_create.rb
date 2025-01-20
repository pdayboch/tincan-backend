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

      begin
        token_exchange_response = public_token_exchange.to_hash
        create_plaid_item(token_exchange_response)
        enqueue_plaid_get_item_details_job(token_exchange_response[:item_id])
        true
      rescue ActiveRecord::RecordNotUnique
        destroy_plaid_item(token_exchange_response)
        raise Error, 'This institution has already been connected'
      end
    end

    private

    def validate_inputs
      raise ArgumentError, 'Public token cannot be blank' if @public_token.blank?
      raise ArgumentError, 'User cannot be nil' if @user.nil?
    end

    def public_token_exchange
      @public_token_exchange ||= PlaidServices::Api.public_token_exchange(@public_token)
    end

    def create_plaid_item(response)
      PlaidItem.create!(
        access_key: response[:access_token],
        item_id: response[:item_id],
        user_id: @user.id
      )
    end

    def enqueue_plaid_get_item_details_job(item_id)
      # TODO: Implement PlaidGetItemDetailsJob.perform_async(item_id)
    end

    # We need to make sure we destroy any Plaid Items on error before we lose
    # the access_token from memory or else we won't be able to destroy it and
    # will continue to get charged for that item.
    # If we can't destroy it, at minimum log the item_id and contact Plaid support.
    def destroy_plaid_item(response)
      PlaidServices::Api.new(response[:access_token]).destroy
    rescue Plaid::ApiError
      Rails.logger.error "Failed to destroy Plaid item id: #{response[:item_id]}"
    end
  end
end
