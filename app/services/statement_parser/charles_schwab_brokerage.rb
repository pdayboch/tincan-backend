# frozen_string_literal: true

module StatementParser
  class CharlesSchwabBrokerage < Base
    INSTITUTION_NAME = 'Charles Schwab'
    ACCOUNT_NAME = 'Brokerage'
    ACCOUNT_TYPE = 'assets'
    ACCOUNT_SUBTYPE = 'investments'

    ALL_MONTHS = 'January|February|March|April|May|June|July|August|September|October|November|December'

    def statement_end_date
      @statement_end_date ||= begin
        match = @text.match(statement_end_date_regex)
        raise("Could not extract statement end date for #{@file_path}") unless match

        parse_statement_date(match)
      end
    end

    def statement_start_date
      @statement_start_date ||= begin
        match = @text.match(statement_start_date_regex)
        raise("Could not extract statement start date for #{@file_path}") unless match

        parse_statement_date(match)
      end
    end

    def statement_balance
      @statement_balance ||= begin
        match = @text.match(statement_balance_regex)
        raise("Could not extract statement balance for #{@file_path}") unless match

        format_amount(match[1])
      end
    end

    def transactions
      if statement_start_date < Date.new(2024, 7, 1)
        TransactionParserPreJul2024.new(@text).transactions
      else
        Rails.logger.error('unable to parse Charles Schwab Brokerage statements after Jul 2024.')
      end
    end

    private

    def statement_start_date_regex
      /
        # Single month format- July 1-30, 2023
        Statement\ Period.*\b(#{ALL_MONTHS})\s+(\d{1,2})-\d{1,2}, # capture start day, dont capture end day
        \s+(\d{4}) # capture year
        |
        # Multi month format- June 30, 2023 to July 29, 2023
        Statement\ Period.*\b(#{ALL_MONTHS}) # capture start month
        \s+(\d{1,2}),\s+(\d{4}) # capture start day and year
        \s+to\s+.*\b(?:#{ALL_MONTHS}) # dont capture end month
        \s+\d{1,2},\s+\d{4} # dont capture end day or year
      /xm
    end

    def statement_end_date_regex
      /
        # Single month format- July 1-30, 2023
        Statement\ Period.*\b(#{ALL_MONTHS})\s+\d{1,2}-(\d{1,2}), # dont capture start day, capture end day
        \s+(\d{4}) # capture year
        |
        # Multi month format- June 30, 2023 to July 29, 2023
        Statement\ Period.*\b(?:#{ALL_MONTHS}) # dont capture start month
        \s+\d{1,2},\s+\d{4} # dont capture start day or year
        \s+to\s+.*\b(#{ALL_MONTHS}) # capture end month
        \s+(\d{1,2}),\s+(\d{4}) # capture end day and year
      /xm
    end

    def extract_statement_date_components(match)
      # single month format
      return [match[1], match[2], match[3]] if match[1]

      # multi month format
      [match[4], match[5], match[6]]
    end

    def parse_statement_date(match)
      date_format = '%B %d %Y'
      month, day, year = extract_statement_date_components(match)
      Date.strptime("#{month} #{day} #{year}", date_format)
    end

    def statement_balance_regex
      /Ending Value.*?\$\s?([\d,]+\.\d{2})/
    end

    def format_amount(amount)
      # Remove the dollar sign and commas, then convert to float
      amount.gsub(/[,$]/, '').to_f.round(2)
    end
  end
end
