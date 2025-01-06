# frozen_string_literal: true

module StatementParser
  class AppleCreditCard < Base
    BANK_NAME = 'Apple'
    ACCOUNT_NAME = 'Credit Card'
    ACCOUNT_TYPE = 'credit card'

    def statement_end_date
      @statement_end_date ||= begin
        date_format = '%b %d %Y'

        match = @text.match(statement_date_regex)
        raise("Could not extract statement end date for #{@file_path}") unless match

        month_day = match[2]
        year = match[3]
        Date.strptime("#{month_day} #{year}", date_format)
      end
    end

    def statement_start_date
      @statement_start_date ||= begin
        date_format = '%b %d %Y'

        match = @text.match(statement_date_regex)
        raise("Could not extract statement start date for #{@file_path}") unless match

        month_day = match[1]
        year = match[3]
        Date.strptime("#{month_day} #{year}", date_format)
      end
    end

    def statement_balance
      @statement_balance ||= begin
        match = @text.match(statement_balance_regex)
        raise("Could not extract statement balance for #{@file_path}") unless match

        match[1].gsub(',', '').to_f
      end
    end

    def transactions
      payments + charges + installments
    end

    private

    def statement_date_regex
      /([A-Za-z]{3} \d{1,2}) — ([A-Za-z]{3} \d{1,2}), (\d{4})/
    end

    def statement_balance_regex
      /^Total Balance\s+\$([\d,]+\.\d{2})/
    end

    def payments
      section = @text.scan(payments_section_regex).flatten
      return [] if section.empty?

      matches = section.first.scan(payment_regex)
      matches.map do |match|
        {
          date: transaction_date(match[0]),
          description: match[1],
          amount: -format_amount(match[2])
        }
      end
    end

    def payments_section_regex
      /
        ^Payments\n
        Date\s+Description\s+Amount\n
        (.*?)
        \nTotalpayments\ for\ this\ period
      /mx
    end

    def payment_regex
      %r{
        (\d{2}/\d{2}/\d{4}) # date
        \s+
        (.*?) # description
        \s+
        (-?\$\d{1,3}(?:,\d{3})*(?:\.\d{2})?) # amount with negative sign
      }x
    end

    def charges
      section = @text.scan(charges_section_regex).flatten
      return [] if section.empty?

      matches = section.first.scan(charge_regex)
      matches.map do |match|
        {
          date: transaction_date(match[0]),
          description: match[1],
          amount: -format_amount(match[2])
        }
      end
    end

    def charges_section_regex
      /
        Transactions\n
        Date\s+Description\s+DailyCash\s+Amount\n
        (.*?)
        \nTotal\ charges,\ credits\ and\ returns
      /mx
    end

    def charge_regex
      %r{
        (\d{2}/\d{2}/\d{4}) # date
        \s+
        (.*?) # description
        \s+
        \d{1,2}%\s+\$\d{1,3}(?:,\d{3})*(?:\.\d{2}) # daily cash
        \s+
        (-?\$\d{1,3}(?:,\d{3})*(?:\.\d{2})?) # amount with negative sign
      }x
    end

    def installments
      section = @text.scan(installments_section_regex).flatten
      return [] if section.empty?

      matches = section.first.scan(installment_regex)
      matches.map do |match|
        {
          date: statement_end_date,
          description: "#{match[0]} - installment",
          amount: -format_amount(match[1])
        }
      end
    end

    def installments_section_regex
      /
        AppleCardMonthly\ Installments\n
        (.*)
        Total\ financed\s+\$\d{1,3}(?:,\d{3})*(?:\.\d{2})?\n
        Total\ payments\ and\ credits\s+\$\d{1,3}(?:,\d{3})*(?:\.\d{2})?\n
        Total\ remaining\s+\$\d{1,3}(?:,\d{3})*(?:\.\d{2})?
      /mx
    end

    def installment_regex
      %r{
          \d{2}/\d{2}/\d{4}\s+ # purchase date
          (.*?)\s+ # description
          (?:\d{1,2}%\s+\$\d{1,3}(?:,\d{3})*\.\d{2}\s+)? # optional daily cash
          \$\d{1,3}(?:,\d{3})*\.\d{2}\n # total purchase amount
          TRANSACTION\ \#.*?\n
          This\ month[’']?s\ installment:\s
          \$(\d{1,3}(?:,\d{3})*\.\d{2}) # this month payment amount
      }mx
    end

    def transaction_date(date)
      date_format = '%m/%d/%Y'
      Date.strptime(date, date_format)
    end

    def format_amount(amount)
      # Remove the dollar sign and commas, then convert to float
      amount.gsub(/[,$]/, '').to_f.round(2)
    end
  end
end
