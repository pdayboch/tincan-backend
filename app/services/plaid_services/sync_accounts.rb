# frozen_string_literal: true

module PlaidServices
  class SyncAccounts
    class DataConsistencyError < StandardError; end

    def initialize(plaid_item, accounts_data)
      @plaid_item = plaid_item
      @accounts_data = accounts_data
      check_params!
      check_item_ids_match!
      @user = plaid_item.user
      @existing_account_ids = @plaid_item.accounts.map(&:plaid_account_id)
    end

    def call
      @accounts_data.accounts.each do |account_data|
        sync_or_create_account(account_data)
      end

      deactivate_missing_accounts
    end

    private

    def sync_or_create_account(account_data)
      if account_exists?(account_data)
        update_account!(account_data)
      else
        create_account!(account_data)
      end
    end

    def update_account!(data)
      update_data = {
        current_balance: balance(data),
        name: name(data)
      }
      local_account(data).update(update_data)
    end

    def create_account!(data)
      account_data = {
        plaid_account_id: plaid_account_id(data),
        name: name(data),
        current_balance: balance(data),
        user_id: @user.id,
        plaid_item_id: @plaid_item.id,
        account_type: account_type(data),
        account_subtype: account_subtype(data)
      }

      Account.create!(account_data)
    end

    def local_account(data)
      @plaid_item.accounts.find_by(plaid_account_id: plaid_account_id(data))
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

    def deactivate_missing_accounts
      missing_account_ids = @existing_account_ids - @accounts_data.accounts.map { |a| plaid_account_id(a) }
      @plaid_item
        .accounts
        .where(plaid_account_id: missing_account_ids)
        .update(active: false)
    end

    def check_params!
      error_msg = "plaid_item must be of type PlaidItem: #{@plaid_item.class}"
      raise ArgumentError, error_msg unless @plaid_item.instance_of? PlaidItem

      error_msg = "accounts_data must be of type Plaid::AccountsGetResponse: #{@accounts_data.class}"
      raise ArgumentError, error_msg unless @accounts_data.instance_of? Plaid::AccountsGetResponse
    end

    def check_item_ids_match!
      accounts_item_id = @accounts_data.item.item_id
      return if @plaid_item.item_id == accounts_item_id

      err_msg = "Plaid Item ID #{@plaid_item.item_id} does not match item_id from accounts_data #{accounts_item_id}"
      raise DataConsistencyError, err_msg
    end
  end
end
