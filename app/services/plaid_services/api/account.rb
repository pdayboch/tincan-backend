# frozen_string_literal: true

module PlaidServices
  class Api
    module Account
      def accounts
        request = Plaid::AccountsGetRequest.new({ access_token: @access_token })
        @client.accounts_get(request)
      rescue Plaid::ApiError => e
        Api.log_plaid_error(e)
        raise e
      end
    end
  end
end
