# frozen_string_literal: true

require 'plaid'

require_relative 'api/token'
require_relative 'api/item'
require_relative 'api/institution'
require_relative 'api/account'
require_relative 'api/transaction'
require_relative 'api/investment'

module PlaidServices
  class Api
    include Api::Token
    include Api::Item
    include Api::Institution
    include Api::Account
    include Api::Transaction
    include Api::Investment

    PRODUCTS = ['transactions'].freeze
    ADDITONAL_PRODUCTS = %w[investments].freeze
    MAX_RETRIES = 3
    MUTATION_ERROR = 'TRANSACTIONS_SYNC_MUTATION_DURING_PAGINATION'

    def self.log_plaid_error(error)
      body = JSON.parse(error.response_body)
      Rails.logger.error(
        'Plaid Service Error: ' \
        "type = #{body['error_type']}; " \
        "code = #{body['error_code']}; " \
        "message = #{body['error_message']}; " \
        "request_id = #{body['request_id']}; " \
        "error_code_reason = #{body['error_code_reason']}; " \
        "docs = #{body['documentation_url']};"
      )
    end

    def initialize(access_token = nil)
      @access_token = access_token
      @client = setup_client
    end

    private

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
