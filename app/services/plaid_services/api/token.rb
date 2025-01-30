# frozen_string_literal: true

module PlaidServices
  class Api
    module Token
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def create_link_token(user)
          request = {
            user: { client_user_id: user.id.to_s },
            client_name: 'Tincan',
            products: PRODUCTS,
            additional_consented_products: ADDITONAL_PRODUCTS,
            transactions: {
              days_requested: 730
            },
            country_codes: ['US'],
            language: 'en'
          }

          new.create_link_token_request(request)
        rescue Plaid::ApiError => e
          log_plaid_error(e)
          raise e
        end

        def public_token_exchange(public_token)
          request = { public_token: public_token }

          new.public_token_exchange(request)
        rescue Plaid::ApiError => e
          log_plaid_error(e)
          raise e
        end
      end

      def create_link_token_request(request)
        link_token_create_req = Plaid::LinkTokenCreateRequest.new(request)
        response = @client.link_token_create(link_token_create_req)
        response.link_token
      end

      def public_token_exchange(request)
        item_public_token_exchange_req = Plaid::ItemPublicTokenExchangeRequest.new(request)
        @client.item_public_token_exchange(item_public_token_exchange_req)
      end
    end
  end
end
