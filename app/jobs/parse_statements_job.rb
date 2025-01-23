# frozen_string_literal: true

class ParseStatementsJob
  include Sidekiq::Job
  sidekiq_options retry: 1

  def perform(root_doc_dir)
    Account.active.find_each do |account|
      # Skip account if statement_directory or parser_class is blank
      next if account.statement_directory.blank? || account.parser_class.blank?

      dir = root_doc_dir.chomp('/')
      account_statements_directory = "#{dir}/#{account.statement_directory}"

      # Skip if the statement directory is missing
      # TODO - raise error if directory missing and bubble up to User facing?
      next unless Dir.exist?(account_statements_directory)

      # Query all processed pdf files for the account:
      processed_file_paths = account.statements.pluck(:pdf_file_path)

      # Iterate through all subdirectories that match "202x"
      Dir.glob("#{account_statements_directory}/202*")
         .select { |path| File.directory?(path) }
         .each do |year_directory|
        # Get all PDF files in the year directory, make sure there are no duplicates.
        file_paths = Dir.glob("#{year_directory}/*.{pdf,PDF}")
        file_paths = Set.new(file_paths).to_a

        file_paths.each do |file_path|
          # Skip the file if processed
          next if processed_file_paths.include?(file_path)

          # Parse the PDF
          parser = account.statement_parser(file_path)
          transactions = parser.transactions

          # Create a new stataement
          statement = account.statements.create!(
            statement_date: parser.statement_end_date,
            statement_balance: parser.statement_balance,
            pdf_file_path: file_path
          )

          # Create transactions associated with the statement
          transactions.each do |transaction_data|
            account.transactions.create!(
              transaction_date: transaction_data[:date],
              statement_transaction_date: transaction_data[:date],
              amount: transaction_data[:amount],
              description: transaction_data[:description],
              statement_description: transaction_data[:description],
              statement: statement
            )
          end
        end
      end
    end
  end
end
