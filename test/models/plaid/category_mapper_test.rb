# frozen_string_literal: true

require 'test_helper'

module Plaid
  class CategoryMapperTest < ActiveSupport::TestCase
    test 'initialization makes single query' do
      query_count = count_queries do
        CategoryMapper.new
      end

      assert_equal 2, query_count, 'Expected initialization to make exactly one query'
    end

    test 'maps known plaid category' do
      auto_transport = categories(:auto_transport)
      gas_fuel = subcategories(:gas_fuel)

      mapper = CategoryMapper.new
      category, subcategory = mapper.map('TRANSPORTATION_GAS')

      assert_equal auto_transport.id, category.id
      assert_equal gas_fuel.id, subcategory.id
    end

    test 'maps unknown category to uncategorized' do
      uncategorized = categories(:uncategorized)
      uncategorized_sub = subcategories(:uncategorized)

      mapper = CategoryMapper.new
      category, subcategory = mapper.map('nonexistant_plaid_category')

      assert_equal uncategorized.id, category.id
      assert_equal uncategorized_sub.id, subcategory.id
    end

    test 'maps nil category to uncategorized' do
      uncategorized = categories(:uncategorized)
      uncategorized_sub = subcategories(:uncategorized)

      mapper = CategoryMapper.new
      category, subcategory = mapper.map(nil)

      assert_equal uncategorized.id, category.id
      assert_equal uncategorized_sub.id, subcategory.id
    end

    private

    def count_queries(&)
      count = 0
      counter_fn = lambda { |_, _, _, _, payload|
        count += 1 unless %w[CACHE SCHEMA TRANSACTION].include?(payload[:name])
      }

      ActiveSupport::Notifications.subscribed(counter_fn, 'sql.active_record', &)

      count
    end
  end
end
