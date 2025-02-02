# frozen_string_literal: true

module Plaid
  class ApiRateLimitError < StandardError
    ERROR_TYPE = 'RATE_LIMIT_EXCEEDED'
  end
end
