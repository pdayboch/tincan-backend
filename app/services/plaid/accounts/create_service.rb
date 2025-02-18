# frozen_string_literal: true

module Plaid
  module Accounts
    class CreateService
      def initialize(plaid_item)
        @item = plaid_item
        @user_id = plaid_item.user_id
      end

      def call(plaid_account)
        mapped_types = AccountTypeMapper.map(plaid_account.type)

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
      end

      private

      def plaid_account_id(data)
        data.account_id
      end

      def name(data)
        data.name || data.official_name
      end

      def balance(data)
        data.balances.current
      end
    end
  end
end
