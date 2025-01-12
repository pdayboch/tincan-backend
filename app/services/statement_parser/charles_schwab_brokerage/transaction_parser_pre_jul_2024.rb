# frozen_string_literal: true

module StatementParser
  class CharlesSchwabBrokerage
    class TransactionParserPreJul2024
      TRADE_KEYWORDS = [
        'Bought',
        'Sold',
        'Cash-In-Lieu',
        'Cash\ in\ Lieu\ Adj'
      ].freeze

      DIVIDEND_KEYWORDS = [
        'Cash\ Dividend',
        'Qualified\ Dividend',
        'Bank\ Interest',
        'Bank\ InterestX,Z',
        'Pr\ Yr\ Cash\ Div'
      ].freeze

      TRANSFER_KEYWORDS = [
        'Journaled\ Funds',
        'Journaled\ Shares'
      ].freeze

      def initialize(statement_text)
        @text = statement_text
      end

      def transactions
        trades + dividends + transfers
      end

      private

      def trades
        matches = @text.scan(trade_regex)
        matches.map do |match|
          {
            date: transaction_date(match[0]),
            description: format_trade_description(match),
            amount: format_amount(match[4])
          }
        end
      end

      def trade_regex
        %r{
          ^\d{2}/\d{2}/\d{2}\s+ # Settle date
          (\d{2}/\d{2}/\d{2})\s+ # 0- Trade date
          (#{TRADE_KEYWORDS.join('|')})\s+ # 1- Transaction
          (.*?)\s+ # 2- Trade Description
          (?:\(?
            (\d{1,3}(?:,\d{3})*\.\d{4}) # 3- Quantity
          \)?\s+)?
          (?:\d{1,3}(?:,\d{3})*\.\d{4}\s+)? # Optional Unit price
          (?:\d{1,3}(?:,\d{3})*\.\d{2}\s+)? # Optional Charges and Interest
          (\(?
            \d{1,3}(?:,\d{3})*\.\d{2} # 4- Amount w optional parentheses
          \)?)\n
          (?:
            (?!Total\s|(?:\d)|Please\ see) # ignore if line is Total or date
            (.*?) # 5- Optional equity description
            (?=\n)
          )?
        }mx
      end

      def format_trade_description(match)
        "#{match[1]} #{match[3]} #{match[2]} #{match[5]}".strip
      end

      def dividends
        matches = @text.scan(dividend_regex)
        matches.map do |match|
          {
            date: transaction_date(match[0]),
            description: "#{match[1]} #{match[2]}",
            amount: format_amount(match[3])
          }
        end
      end

      def dividend_regex
        %r{
          (\d{2}/\d{2}/\d{2})\s+ # 0- Transaction date
          \d{2}/\d{2}/\d{2}\s+ # Process date
          (#{DIVIDEND_KEYWORDS.join('|')})\s+ # 1- Transaction
          (.*?)\s+ # 2- Description
          (\(?
            \d{1,3}(?:,\d{3})*\.\d{2} # 3- Amount w optional parentheses
          \)?)
        }mx
      end

      def transfers
        matches = @text.scan(transfer_regex)
        matches.map do |match|
          {
            date: transaction_date(match[0]),
            description: format_transfer_description(match),
            amount: format_amount(match[4])
          }
        end
      end

      def transfer_regex
        %r{
          (\d{2}/\d{2}/\d{2})\s+ # 0- Transaction date
          \d{2}/\d{2}/\d{2}\s+ # Process date
          (#{TRANSFER_KEYWORDS.join('|')})\s+ # 1- Transaction
          (.*?)\s+ # 2- Description
          (?:\(?
            (\d{1,3}(?:,\d{3})*\.\d{4}) # 3- Optional Quantity
          \)?\s+)?
          (?:\d{1,3}(?:,\d{3})*\.\d{4}\s+)? # Optional Unit Price
          (\(?
            \d{1,3}(?:,\d{3})*\.\d{2} # 4- Amount w optional parentheses
          \)?)
        }mx
      end

      def format_transfer_description(match)
        quantity = match[3] ? " #{match[3]}" : ''
        "#{match[1]}#{quantity} #{match[2]}"
      end

      def transaction_date(date)
        date_format = '%m/%d/%y'
        Date.strptime(date, date_format)
      end

      def format_amount(amount)
        # Check if the amount is wrapped in parentheses
        is_negative = amount.start_with?('(') && amount.end_with?(')')
        sanitized_amount = amount.tr('()', '').gsub(',', '')
        is_negative ? -sanitized_amount.to_f : sanitized_amount.to_f
      end
    end
  end
end
