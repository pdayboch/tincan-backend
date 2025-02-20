# frozen_string_literal: true

module PlaidServices
  class Api
    module Investment
      def investments_transactions(start_date:, end_date:, offset: 0)
        request = Plaid::InvestmentsTransactionsGetRequest.new(
          access_token: @access_token,
          start_date: start_date,
          end_date: end_date,
          options: {
            count: 500,
            offset: offset
          }
        )

        @client.investments_transactions_get(request)
      rescue Plaid::ApiError => e
        Api.log_plaid_error(e)
        raise e
      end
    end
  end
end
