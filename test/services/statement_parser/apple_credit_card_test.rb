# frozen_string_literal: true

require 'test_helper'

module StatementParser
  class AppleCreditCardTest < ActiveSupport::TestCase
    setup do
      @file_path = 'path/to/statement.pdf'
    end

    test 'statement_end_date' do
      mock_text = <<~TEXT
        Statement
        AppleCard Customer
        fname lname, email@email.com                    Nov 1 — Nov 30, 2024
        If you'd like to receive Apple Card
      TEXT
      AppleCreditCard.any_instance.stubs(:statement_text).returns(mock_text)
      parser = AppleCreditCard.new(@file_path)

      assert_equal Date.new(2024, 11, 30), parser.statement_end_date
    end

    test 'raises error when statement_end_date not detected' do
      mock_text = 'Invalid text'
      AppleCreditCard.any_instance.stubs(:statement_text).returns(mock_text)
      parser = AppleCreditCard.new(@file_path)

      assert_raises(RuntimeError, "Could not extract statement end date for #{@file_path}") do
        parser.statement_end_date
      end
    end

    test 'statement_start_date' do
      mock_text = <<~TEXT
        Statement
        AppleCard Customer
        fname lname, email@email.com                    Nov 1 — Nov 30, 2024
        If you'd like to receive Apple Card
      TEXT
      AppleCreditCard.any_instance.stubs(:statement_text).returns(mock_text)
      parser = AppleCreditCard.new(@file_path)

      assert_equal Date.new(2024, 11, 1), parser.statement_start_date
    end

    test 'raises error when statement_start_date not detected' do
      mock_text = 'Invalid text'
      AppleCreditCard.any_instance.stubs(:statement_text).returns(mock_text)
      parser = AppleCreditCard.new(@file_path)

      assert_raises(RuntimeError, "Could not extract statement start date for #{@file_path}") do
        parser.statement_start_date
      end
    end

    test 'statement_balance' do
      mock_text = <<~TEXT
        Previous Monthly Balance                $23.42
        as of Oct 31, 2024
        Previous Total Balance                  $23.42
        as of Oct 31, 2024
        Total Balance                        $1,115.98
        as of Nov 30, 2024
      TEXT
      AppleCreditCard.any_instance.stubs(:statement_text).returns(mock_text)
      parser = AppleCreditCard.new(@file_path)

      assert_equal 1115.98, parser.statement_balance
    end

    test 'raises error when statement_balance not detected' do
      mock_text = 'Invalid text'
      AppleCreditCard.any_instance.stubs(:statement_text).returns(mock_text)
      parser = AppleCreditCard.new(@file_path)

      assert_raises(RuntimeError, "Could not extract statement balance for #{@file_path}") do
        parser.statement_balance
      end
    end

    test 'single page of payments' do
      mock_text = <<~TEXT
        Payments
        Date           Description                        Amount
        11/30/2022     ACH Deposit Internet transfer      -$23.31
        Totalpayments for this period
      TEXT
      AppleCreditCard.any_instance.stubs(:statement_text).returns(mock_text)
      parser = AppleCreditCard.new(@file_path)

      transactions = parser.transactions
      assert_equal 1, transactions.size

      assert_includes transactions, {
        date: Date.new(2022, 11, 30),
        description: 'ACH Deposit Internet transfer',
        amount: 23.31
      }
    end

    test 'multiple pages of payments' do
      mock_text = <<~TEXT
        Payments
        Date           Description                     Amount
        11/25/2022     ACH Deposit Internet transfer   -$39.33
        Apple Card is issued by Goldman Sachs Bank USA, Salt Lake City Branch.
        Page 2 /5
        Statement
        AppleCard Customer
        John Name, email@email.com     Nov 1 — Nov 30, 2022
        Payments
        Date           Description                          Amount
        11/30/2022     ACH Deposit Internet transfer       -$79.24
        Totalpayments for this period
      TEXT
      AppleCreditCard.any_instance.stubs(:statement_text).returns(mock_text)
      parser = AppleCreditCard.new(@file_path)

      transactions = parser.transactions
      assert_equal 2, transactions.size

      assert_includes transactions, {
        date: Date.new(2022, 11, 25),
        description: 'ACH Deposit Internet transfer',
        amount: 39.33
      }

      assert_includes transactions, {
        date: Date.new(2022, 11, 30),
        description: 'ACH Deposit Internet transfer',
        amount: 79.24
      }
    end

    test 'single page of charges' do
      mock_text = <<~TEXT
        Transactions
        Date             Description             DailyCash        Amount
        10/31/2022       SQ CAFE 162 Buck Ave    2%   $0.14        $6.97
        11/12/2022       ACE HDWE 5 Howard       2%   $0.56       $28.07
        3% Daily Cash at Ace Hardware            1%   $0.28
        11/13/2022         TST* SUPER DUPER      2%   $0.15        $7.59
        Total Daily Cash this month                  $2.15
        Total charges, credits and returns
      TEXT
      AppleCreditCard.any_instance.stubs(:statement_text).returns(mock_text)
      parser = AppleCreditCard.new(@file_path)

      transactions = parser.transactions
      assert_equal 3, transactions.size

      assert_includes transactions, {
        date: Date.new(2022, 10, 31),
        description: 'SQ CAFE 162 Buck Ave',
        amount: -6.97
      }

      assert_includes transactions, {
        date: Date.new(2022, 11, 12),
        description: 'ACE HDWE 5 Howard',
        amount: -28.07
      }

      assert_includes transactions, {
        date: Date.new(2022, 11, 13),
        description: 'TST* SUPER DUPER',
        amount: -7.59
      }
    end

    test 'multiple pages of charges' do
      mock_text = <<~TEXT
        Transactions
        Date             Description             DailyCash        Amount
        11/12/2022       ACE HDWE 5 Howard       2%   $0.56       $28.07
        3% Daily Cash at Ace Hardware            1%   $0.28
        11/12/2022         TST* SUPER DUPER      2%   $0.15        $7.59
        Apple Card is issued by Goldman Sachs Bank USA, Salt Lake City Branch.
        Page 2 /5
        Statement
        AppleCard Customer
        John Name, email@email.com                Nov 1 — Nov 30, 2022
        Transactions
        Date             Description             DailyCash         Amount
        11/29/2022       CLOVER KILAUEA FISH     2%   $0.82        $41.00
        Total Daily Cash this month                  $3.12
        Total charges, credits and returns
      TEXT
      AppleCreditCard.any_instance.stubs(:statement_text).returns(mock_text)
      parser = AppleCreditCard.new(@file_path)

      transactions = parser.transactions
      assert_equal 3, transactions.size

      assert_includes transactions, {
        date: Date.new(2022, 11, 12),
        description: 'ACE HDWE 5 Howard',
        amount: -28.07
      }

      assert_includes transactions, {
        date: Date.new(2022, 11, 12),
        description: 'TST* SUPER DUPER',
        amount: -7.59
      }

      assert_includes transactions, {
        date: Date.new(2022, 11, 29),
        description: 'CLOVER KILAUEA FISH',
        amount: -41.00
      }
    end

    test 'installments' do
      mock_text = <<~TEXT
        fname lname, email@email.com                Nov 1 — Nov 30, 2024
        AppleCardMonthly Installments
        Dates                  Description             DailyCash      Amounts
        02/12/2022             Apple Online Store                    $1,049.00
        TRANSACTION #12345678abcd
        This months installment: $30.23
        Final installment: Apr 20, 2022
        Total financed                                               $1,049.00
        Total payments and credits                                   $274.44
        Total remaining                                              $874.66
      TEXT
      AppleCreditCard.any_instance.stubs(:statement_text).returns(mock_text)
      parser = AppleCreditCard.new(@file_path)

      transactions = parser.transactions
      assert_equal 1, transactions.size

      assert_includes transactions, {
        date: Date.new(2024, 11, 30),
        description: 'Apple Online Store - installment',
        amount: -30.23
      }
    end

    test 'multiple installments' do
      mock_text = <<~TEXT
        fname lname, email@email.com                Oct 1 — Oct 31, 2024
        AppleCardMonthly Installments
        Dates                  Description             DailyCash      Amounts
        02/12/2022             Apple Online Store                    $1,049.00
        TRANSACTION #12345678abcd
        This months installment: $22.87
        Final installment: Sep 30, 2023
        10/12/2022             Apple Online Store                    $179.00
        TRANSACTION #abcd12345
        This months installment: $29.85
        This is your final installment.
        Total financed                                               $1,049.00
        Total payments and credits                                   $274.44
        Total remaining                                              $874.66
      TEXT
      AppleCreditCard.any_instance.stubs(:statement_text).returns(mock_text)
      parser = AppleCreditCard.new(@file_path)

      transactions = parser.transactions
      assert_equal 2, transactions.size

      assert_includes transactions, {
        date: Date.new(2024, 10, 31),
        description: 'Apple Online Store - installment',
        amount: -22.87
      }

      assert_includes transactions, {
        date: Date.new(2024, 10, 31),
        description: 'Apple Online Store - installment',
        amount: -29.85
      }
    end

    test 'installments with optional apostrophe in month' do
      mock_text = <<~TEXT
        fname lname, email@email.com                Nov 1 — Nov 30, 2024
        AppleCardMonthly Installments
        Dates                  Description             DailyCash      Amounts
        02/12/2022             Apple Online Store                    $1,049.00
        TRANSACTION #12345678abcd
        This month's installment: $30.23
        Final installment: Apr 20, 2022
        Total financed                                               $1,049.00
        Total payments and credits                                   $274.44
        Total remaining                                              $874.66
      TEXT
      AppleCreditCard.any_instance.stubs(:statement_text).returns(mock_text)
      parser = AppleCreditCard.new(@file_path)

      transactions = parser.transactions
      assert_equal 1, transactions.size

      assert_includes transactions, {
        date: Date.new(2024, 11, 30),
        description: 'Apple Online Store - installment',
        amount: -30.23
      }
    end

    test 'installments with optional curly apostrophe in month' do
      mock_text = <<~TEXT
        fname lname, email@email.com                Nov 1 — Nov 30, 2024
        AppleCardMonthly Installments
        Dates                  Description             DailyCash      Amounts
        02/12/2022             Apple Online Store                    $1,049.00
        TRANSACTION #12345678abcd
        This month’s installment: $30.23
        Final installment: Apr 20, 2022
        Total financed                                               $1,049.00
        Total payments and credits                                   $274.44
        Total remaining                                              $874.66
      TEXT
      AppleCreditCard.any_instance.stubs(:statement_text).returns(mock_text)
      parser = AppleCreditCard.new(@file_path)

      transactions = parser.transactions
      assert_equal 1, transactions.size

      assert_includes transactions, {
        date: Date.new(2024, 11, 30),
        description: 'Apple Online Store - installment',
        amount: -30.23
      }
    end

    test 'transactions combines payments charges and installments' do
      mock_text = <<~TEXT
        fname lname, email@email.com                Nov 1 — Nov 30, 2022
        Payments
        Date           Description                        Amount
        11/30/2022     ACH Deposit Internet transfer      -$23.31
        Totalpayments for this period
        Transactions
        Date             Description             DailyCash        Amount
        11/12/2022       ACE HDWE 5 Howard       2%   $0.56       $28.07
        Total Daily Cash this month                  $2.15
        Total charges, credits and returns
        AppleCardMonthly Installments
        Dates                  Description             DailyCash      Amounts
        02/12/2022             Apple Online Store                    $1,049.00
        TRANSACTION #12345678abcd
        This months installment: $30.23
        Final installment: Apr 20, 2023
        Total financed                                               $1,049.00
        Total payments and credits                                   $274.44
        Total remaining                                              $874.66
      TEXT
      AppleCreditCard.any_instance.stubs(:statement_text).returns(mock_text)
      parser = AppleCreditCard.new(@file_path)

      transactions = parser.transactions
      assert_equal 3, transactions.size

      assert_includes transactions, {
        date: Date.new(2022, 11, 30),
        description: 'ACH Deposit Internet transfer',
        amount: 23.31
      }

      assert_includes transactions, {
        date: Date.new(2022, 11, 12),
        description: 'ACE HDWE 5 Howard',
        amount: -28.07
      }

      assert_includes transactions, {
        date: Date.new(2022, 11, 30),
        description: 'Apple Online Store - installment',
        amount: -30.23
      }
    end
  end
end
