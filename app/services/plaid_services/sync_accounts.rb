# frozen_string_literal: true

module PlaidServices
  class SyncAccounts
    class PlaidApiRateLimitError < StandardError; end

    RATE_LIMIT_EXCEEDED = 'RATE_LIMIT_EXCEEDED'

    def initialize(plaid_item)
      @item = plaid_item
      check_params!
      @api = PlaidServices::Api.new(@item.access_key)
      @user_id = plaid_item.user_id
      @existing_accounts = @item.accounts
      @processed_account_ids = []
    end

    def call
      plaid_data = @api.accounts
      sync_item_data(plaid_data.item)
      sync_accounts(plaid_data.accounts)

      deactivate_missing_accounts!
      @item.mark_accounts_as_synced
    rescue Plaid::ApiError => e
      handle_api_error(e)
    end

    private

    def sync_item_data(plaid_item_data)
      # TODO
    end

    def sync_accounts(plaid_accounts_data)
      plaid_accounts_data.each do |plaid_account_data|
        sync_account(plaid_account_data)
        @processed_account_ids << plaid_account_data.account_id
      end
    end

    def sync_account(plaid_account_data)
      account = local_account(plaid_account_data)
      if account
        Plaid::Accounts::UpdateService.new(@item, account).call(plaid_account_data)
      else
        Plaid::Accounts::CreateService.new(@item).call(plaid_account_data)
      end
    rescue Plaid::AccountTypeMapper::InvalidAccountType => e
      handle_invalid_account_type(e)
    end

    def local_account(plaid_account_data)
      @existing_accounts.find_by(plaid_account_id: plaid_account_data.account_id)
    end

    def deactivate_missing_accounts!
      missing_account_ids = @existing_accounts.map(&:plaid_account_id) -
                            @processed_account_ids
      @item
        .accounts
        .where(plaid_account_id: missing_account_ids)
        .update(active: false)
    end

    def check_params!
      error_msg = "plaid_item must be of type PlaidItem: #{@item.class}"
      raise ArgumentError, error_msg unless @item.instance_of? PlaidItem
    end

    def handle_api_error(error)
      raise error unless error.data['error_type'] == RATE_LIMIT_EXCEEDED

      raise PlaidApiRateLimitError
    end

    def handle_invalid_account_type(error)
      Rails.logger.error("#{error.message}. Skipping account creation.")
    end
  end
end
