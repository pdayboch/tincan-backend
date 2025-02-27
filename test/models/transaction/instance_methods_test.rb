# frozen_string_literal: true

require 'test_helper'

class TransactionInstanceMethodsTest < ActiveSupport::TestCase
  test 'uncategorized? returns true when uncategorized' do
    transaction = transactions(:uncategorized)
    assert transaction.uncategorized?
  end

  test 'uncategorized? returns false when not uncategorized' do
    transaction = transactions(:with_category)
    assert_not transaction.uncategorized?
  end
end
