# frozen_string_literal: true

module StatementParser
  class MockStatementParser < Base
    INSTITUTION_NAME = 'Dummy Bank'
    ACCOUNT_NAME = 'Dummy Account'
    ACCOUNT_TYPE = 'assets'
    ACCOUNT_SUBTYPE = 'cash'

    def statement_end_date
      Date.new(2023, 1, 31)
    end

    def statement_balance
      1234.56
    end

    def transactions
      [
        { date: Date.new(2023, 1, 1), amount: 100.0, description: 'Transaction 1' },
        { date: Date.new(2023, 1, 2), amount: 200.0, description: 'Transaction 2' }
      ]
    end
  end
end
