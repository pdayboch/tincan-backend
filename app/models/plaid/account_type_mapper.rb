# frozen_string_literal: true

module Plaid
  class AccountTypeMapper
    class InvalidAccountType < StandardError; end

    ACCOUNT_TYPE_MAPPINGS = {
      'depository' => { type: 'assets', subtype: 'cash' },
      'investment' => { type: 'assets', subtype: 'investments' },
      'credit' => { type: 'liabilities', subtype: 'credit cards' },
      'loan' => { type: 'liabilities', subtype: 'loans' },
      'other' => { type: 'assets', subtype: 'other' }
    }.freeze

    def self.map(plaid_type)
      ACCOUNT_TYPE_MAPPINGS[plaid_type.downcase] ||
        (raise InvalidAccountType, "Unknown Plaid account type: #{plaid_type}")
    end
  end
end
