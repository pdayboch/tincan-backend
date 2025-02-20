# frozen_string_literal: true

module PlaidServices
  module Accounts
    class CreateService
      def initialize(plaid_item)
        @item = plaid_item
        @user_id = plaid_item.user_id
      end

      def call(plaid_account)
        mapped_types = Plaid::AccountTypeMapper.map(plaid_account.type)

        account_data = {
          plaid_account_id: plaid_account_id(plaid_account),
          name: name(plaid_account),
          current_balance: balance(plaid_account),
          user_id: @user_id,
          plaid_item_id: @item.id,
          account_type: mapped_types[:type],
          account_subtype: mapped_types[:subtype],
          institution_name: @item.reload.institution_name
        }

        Account.create!(account_data)
      rescue ActiveRecord::RecordNotUnique
        msg = 'Attempted to create a Plaid account which already exists: ' \
              "plaid_account_id: #{plaid_account_id(plaid_account)}"
        Rails.logger.error("PlaidServices::Accounts::Create - #{msg}")
        @item.accounts.find_by!(plaid_account_id: plaid_account.account_id)
      end

      private

      def plaid_account_id(data)
        data.account_id
      end

      def name(data)
        data.name || data.official_name
      end

      def balance(data)
        data.balances.try(:current)
      end
    end
  end
end
