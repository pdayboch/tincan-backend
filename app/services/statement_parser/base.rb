# frozen_string_literal: true

require 'pdf-reader'

module StatementParser
  class Base
    def initialize(file_path)
      Rails.logger.info("StatementParser Base: parsing #{file_path}")
      @file_path = file_path
      @text = statement_text
    end

    def statement_end_date
      raise NotImplementedError, 'Parser classes must implement the statement_end_date method'
    end

    def statement_start_date
      raise NotImplementedError, 'Parser classes must implement the statement_start_date method'
    end

    def statement_balance
      raise NotImplementedError, 'Parser classes must implement the statement_balance method'
    end

    def transactions
      raise NotImplementedError, 'Parser classes must implement the transactions method'
    end

    private

    def statement_text
      reader = PDF::Reader.new(@file_path)
      pages = reader.pages.map(&:text)
      clean_and_join_pages(pages)
    end

    # Remove leading and trailing whitespace but preserve internal whitespace.
    def clean_and_join_pages(pages)
      pages.map do |page|
        page.split("\n")
            .map(&:strip)
            .reject(&:empty?)
            .join("\n")
      end
        .join("\n")
    end
  end
end
