# frozen_string_literal: true

module PlaidServices
  class SyncAccounts
    class PlaidApiRateLimitError < StandardError; end

    RATE_LIMIT_EXCEEDED = 'RATE_LIMIT_EXCEEDED'

    def initialize(plaid_item)
      @item = plaid_item
      check_params!
      @user = plaid_item.user
      @existing_account_ids = @item.accounts.map(&:plaid_account_id)
    end

    def call
      accounts_data = fetch_accounts_data
      accounts_data.each do |account_data|
        sync_or_create_account(account_data)
      end

      deactivate_missing_accounts(accounts_data)
      @item.mark_accounts_as_synced
    end

    private

    def fetch_accounts_data
      PlaidServices::Api.new(@item.access_key)
                        .accounts
                        .accounts
    rescue Plaid::ApiError => e
      handle_api_error(e)
    end

    def sync_or_create_account(account_data)
      if account_exists?(account_data)
        update_account(account_data)
      else
        create_account!(account_data)
      end
    end

    def update_account(data)
      update_data = {
        current_balance: balance(data),
        name: name(data)
      }
      local_account(data).update(update_data)
    end

    def create_account!(data)
      mapped_types = Plaid::AccountTypeMapper.map(account_type(data))

      account_data = {
        plaid_account_id: plaid_account_id(data),
        name: name(data),
        current_balance: balance(data),
        user_id: @user.id,
        plaid_item_id: @item.id,
        account_type: mapped_types[:type],
        account_subtype: mapped_types[:subtype]
      }

      Account.create!(account_data)
    rescue Plaid::AccountTypeMapper::InvalidAccountType => e
      handle_invalid_account_type(e)
    end

    def local_account(data)
      @item.accounts.find_by(plaid_account_id: plaid_account_id(data))
    end

    def account_exists?(data)
      @existing_account_ids.include?(plaid_account_id(data))
    end

    def plaid_account_id(data)
      data.account_id
    end

    def name(data)
      data.name || data.official_name
    end

    def balance(data)
      data.balances.current
    end

    def account_type(data)
      data.type
    end

    def account_subtype(data)
      data.subtype
    end

    def missing_account_ids(accounts_data)
      @existing_account_ids - accounts_data.map { |a| plaid_account_id(a) }
    end

    def deactivate_missing_accounts(accounts_data)
      missing_account_ids = missing_account_ids(accounts_data)
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
