# frozen_string_literal: true

require 'test_helper'
require 'support/mock_statement_parser'

class ParseStatementsJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
    @root_doc_dir = Dir.mktmpdir
    @statement_directory = 'test account'
    year_directory = File.join(@root_doc_dir, @statement_directory, '2023').strip
    FileUtils.mkdir_p(year_directory)
    File.write(File.join(year_directory, 'statement.pdf').strip, 'PDF content')
    @pdf_file_path = File.join(year_directory, 'statement.pdf').strip
  end

  test 'should process statements and transactions' do
    PDF::Reader.stub(:new, mock_pdf_reader) do
      account = @user.accounts.create!(
        institution_name: 'Bank',
        name: 'Test Account',
        statement_directory: @statement_directory,
        parser_class: 'MockStatementParser'
      )

      assert_difference 'Statement.count', 1 do
        assert_difference 'Transaction.count', 2 do
          ParseStatementsJob.perform_now(@root_doc_dir)
        end
      end

      statement = account.statements.last
      assert_equal Date.new(2023, 1, 31), statement.statement_date
      assert_equal 1234.56, statement.statement_balance
      assert_equal @pdf_file_path, statement.pdf_file_path

      transactions = statement.transactions
      assert_equal 2, transactions.count

      transaction1 = transactions.find_by(description: 'Transaction 1')
      assert_equal Date.new(2023, 1, 1), transaction1.transaction_date
      assert_equal 100.0, transaction1.amount

      transaction2 = transactions.find_by(description: 'Transaction 2')
      assert_equal Date.new(2023, 1, 2), transaction2.transaction_date
      assert_equal 200.0, transaction2.amount
    end
  end

  test 'should skip account if statement_directory is blank' do
    PDF::Reader.stub(:new, mock_pdf_reader) do
      @user.accounts.create!(
        institution_name: 'Bank',
        name: 'Account without statement_dir',
        parser_class: 'MockStatementParser'
      )

      assert_no_difference 'Statement.count' do
        assert_no_difference 'Transaction.count' do
          ParseStatementsJob.perform_now(@root_doc_dir)
        end
      end
    end
  end

  test 'should skip account if parser_class is blank' do
    PDF::Reader.stub(:new, mock_pdf_reader) do
      @user.accounts.create!(
        institution_name: 'Bank',
        name: 'Account without parser class',
        statement_directory: @statement_directory
      )

      assert_no_difference 'Statement.count' do
        assert_no_difference 'Transaction.count' do
          ParseStatementsJob.perform_now(@root_doc_dir)
        end
      end
    end
  end

  test 'should skip if statement directory is missing from filesystem' do
    PDF::Reader.stub(:new, mock_pdf_reader) do
      @user.accounts.create!(
        institution_name: 'Bank',
        name: 'Account but missing account directory',
        statement_directory: 'other account',
        parser_class: 'MockStatementParser'
      )

      assert_no_difference 'Statement.count' do
        assert_no_difference 'Transaction.count' do
          ParseStatementsJob.perform_now(@root_doc_dir)
        end
      end
    end
  end

  test 'should skip processed files' do
    PDF::Reader.stub(:new, mock_pdf_reader) do
      account = @user.accounts.create!(
        institution_name: 'Bank',
        name: 'Account with processed statements',
        statement_directory: @statement_directory,
        parser_class: 'MockStatementParser'
      )
      account.statements.create!(
        statement_date: Date.new(2023, 1, 31),
        statement_balance: 1234.56,
        pdf_file_path: @pdf_file_path
      )

      assert_no_difference 'Statement.count' do
        assert_no_difference 'Transaction.count' do
          ParseStatementsJob.perform_now(@root_doc_dir)
        end
      end
    end
  end

  private

  def mock_pdf_reader
    # Mock the PDF::Reader to avoid needing an actual valid PDF file
    mock_page = Minitest::Mock.new
    mock_page.expect(:text, 'Dummy PDF text')

    mock_pdf_reader = Minitest::Mock.new
    mock_pdf_reader.expect(:pages, [mock_page])
    mock_pdf_reader
  end
end
