# frozen_string_literal: true

module Plaid
  module Accounts
    class UpdateService
      def initialize(plaid_item, account)
        @item = plaid_item
        @account = account
      end

      def call(plaid_account)
        update_data = {
          current_balance: balance(plaid_account),
          name: name(plaid_account)
        }

        institution_name = @item.reload.institution_name
        update_data[:institution_name] = institution_name if institution_name

        @account.update(update_data)
      end

      private

      def name(data)
        data.name || data.official_name
      end

      def balance(data)
        data.balances.current
      end
    end
  end
end
