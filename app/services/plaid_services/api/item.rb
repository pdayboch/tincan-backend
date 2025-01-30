# frozen_string_literal: true

module PlaidServices
  class Api
    module Item
      def show
        req = Plaid::ItemGetRequest.new(
          access_token: @access_token
        )
        @client.item_get(req)
      rescue Plaid::ApiError => e
        Api.log_plaid_error(e)
        raise e
      end

      def destroy
        req = Plaid::ItemRemoveRequest.new(
          access_token: @access_token
        )
        resp = @client.item_remove(req)
        Rails.logger.info('Plaid Api: Item removed successfully')
        resp
      rescue Plaid::ApiError => e
        Api.log_plaid_error(e)
        raise e
      end
    end
  end
end
