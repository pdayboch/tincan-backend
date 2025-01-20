# frozen_string_literal: true

require 'plaid'

module PlaidServices
  class Api
    PLAID_PRODUCTS = ['transactions'].freeze
    MAX_RETRIES = 3
    MUTATION_ERROR = 'TRANSACTIONS_SYNC_MUTATION_DURING_PAGINATION'

    class TransactionSyncError < StandardError; end

    def initialize(access_token = nil)
      @access_token = access_token
      @client = setup_client
    end

    def self.create_link_token(user)
      request = {
        user: { client_user_id: user.id.to_s },
        client_name: 'Tincan',
        products: PLAID_PRODUCTS,
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

    def self.public_token_exchange(public_token)
      request = { public_token: public_token }

      new.public_token_exchange(request)
    rescue Plaid::ApiError => e
      log_plaid_error(e)
      raise e
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

    ## Item APIs
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
      @client.item_remove(req)
    rescue Plaid::ApiError => e
      Api.log_plaid_error(e)
      raise e
    end

    ## Account APIs
    def accounts
      request = Plaid::AccountsGetRequest.new({ access_token: @access_token })
      @client.accounts_get(request)
    rescue Plaid::ApiError => e
      Api.log_plaid_error(e)
      raise e
    end

    def transactions_sync(initial_cursor = nil)
      cursor = initial_cursor || ''
      original_cursor = nil
      added = []
      modified = []
      removed = []
      retry_count = 0

      begin
        has_more = true
        while has_more
          response = fetch_transactions_page(cursor)

          # Set original cursor before updating cursor
          original_cursor = cursor if has_more && original_cursor.nil?

          cursor = response.next_cursor
          added += response.added
          modified += response.modified
          removed += response.removed
          has_more = response.has_more
        end

        {
          next_cursor: cursor,
          added: added,
          modified: modified,
          removed: removed
        }
      rescue Plaid::ApiError => e
        Api.log_plaid_error(e)

        if mutation_during_pagination?(e) && !original_cursor.nil? && retry_count < MAX_RETRIES
          retry_count += 1
          added = []
          modified = []
          removed = []
          cursor = original_cursor
          retry
        end

        raise TransactionSyncError, 'Failed to sync transactions.'
      end
    end

    def self.log_plaid_error(error)
      body = JSON.parse(error.response_body)
      Rails.logger.error(
        'Plaid Service Error: ' \
        "type = #{body['error_type']} " \
        "code = #{body['error_code']} " \
        "message = #{body['error_message']} " \
        "request_id = #{body['request_id']} " \
        "error_code_reason = #{body['error_code_reason']} " \
        "docs = #{body['documentation_url']}"
      )
    end

    private

    def fetch_transactions_page(cursor)
      request = Plaid::TransactionsSyncRequest.new(
        access_token: @access_token,
        cursor: cursor
      )
      @client.transactions_sync(request)
    end

    def mutation_during_pagination?(error)
      body = JSON.parse(error.response_body)
      body['error_code'] == MUTATION_ERROR
    end

    def setup_client
      configuration = Plaid::Configuration.new
      configuration.server_index = plaid_environment
      configuration.api_key['PLAID-CLIENT-ID'] = ENV.fetch('PLAID_CLIENT_ID', nil)
      configuration.api_key['PLAID-SECRET'] = ENV.fetch('PLAID_SECRET', nil)

      api_client = Plaid::ApiClient.new(configuration)
      Plaid::PlaidApi.new(api_client)
    end

    def plaid_environment
      if Rails.env.production?
        Plaid::Configuration::Environment['production']
      else
        Plaid::Configuration::Environment['sandbox']
      end
    end
  end
end
